require "./spec_helper"

# Test structs for nested TLV::Value types
# This reproduces the issue we're having with Matter PBKDF Parameter Response
module NestedValueTest
  # Simplified version of Matter's PbkdfParamResponse structure
  # This has:
  # - Some required fields (initiator_random, responder_random, responder_session_id)
  # - One optional nested field (pbkdf_parameters) that is itself a TLV structure
  struct PbkdfResponse
    include TLV::Serializable

    @[TLV::Field(tag: 1)]
    property initiator_random : Bytes

    @[TLV::Field(tag: 2)]
    property responder_random : Bytes

    @[TLV::Field(tag: 3)]
    property responder_session_id : UInt16

    # This is the problematic field - a nested TLV structure stored as TLV::Value
    # In Matter spec, tag 4 contains a nested structure with:
    #   tag 1: iterations (UInt32)
    #   tag 2: salt (Bytes)
    @[TLV::Field(tag: 4, optional: true)]
    property pbkdf_parameters : TLV::Value?

    def initialize(
      @initiator_random : Bytes,
      @responder_random : Bytes,
      @responder_session_id : UInt16,
      iterations : UInt32? = nil,
      salt : Bytes? = nil,
    )
      # Build the nested structure if parameters are provided
      if iterations && salt
        @pbkdf_parameters = {
          1_u8 => iterations,
          2_u8 => salt,
        } of TLV::Tag => TLV::Value
      else
        @pbkdf_parameters = nil
      end
    end
  end

  # Another test case: optional nested value in a simpler structure
  struct SimpleNestedValue
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property id : UInt16

    # Any TLV::Value - could be a hash, array, primitive, etc.
    @[TLV::Field(tag: 1, optional: true)]
    property metadata : TLV::Value?

    def initialize(@id : UInt16, @metadata : TLV::Value? = nil)
    end
  end
end

describe "TLV::Serializable with nested TLV::Value fields" do
  describe "PbkdfResponse with nested structure" do
    it "encodes and decodes with pbkdf_parameters" do
      # Create test data
      initiator_random = Bytes.new(32, 0xAA_u8)
      responder_random = Bytes.new(32, 0xBB_u8)
      responder_session_id = 1234_u16
      iterations = 1000_u32
      salt = Bytes.new(32, 0xCC_u8)

      # Create response with nested parameters
      response = NestedValueTest::PbkdfResponse.new(
        initiator_random: initiator_random,
        responder_random: responder_random,
        responder_session_id: responder_session_id,
        iterations: iterations,
        salt: salt
      )

      # Verify the nested structure was created correctly
      response.pbkdf_parameters.should_not be_nil
      pbkdf = response.pbkdf_parameters.not_nil!
      pbkdf.should be_a(Hash(TLV::Tag, TLV::Value))
      pbkdf_hash = pbkdf.as(Hash(TLV::Tag, TLV::Value))
      pbkdf_hash[1_u8].should eq(iterations)
      pbkdf_hash[2_u8].should eq(salt)

      # Encode to TLV bytes
      encoded = response.to_slice

      # Decode from TLV bytes - THIS IS WHERE IT FAILS
      decoded = NestedValueTest::PbkdfResponse.new(encoded)

      # Verify all fields
      decoded.initiator_random.should eq(initiator_random)
      decoded.responder_random.should eq(responder_random)
      decoded.responder_session_id.should eq(responder_session_id)

      # Verify nested structure
      decoded.pbkdf_parameters.should_not be_nil
      decoded_pbkdf = decoded.pbkdf_parameters.not_nil!
      decoded_pbkdf.should be_a(Hash(TLV::Tag, TLV::Value))
      decoded_pbkdf_hash = decoded_pbkdf.as(Hash(TLV::Tag, TLV::Value))
      decoded_pbkdf_hash[1_u8].should eq(iterations)
      decoded_pbkdf_hash[2_u8].as(Bytes).should eq(salt)
    end

    it "encodes and decodes without pbkdf_parameters (optional field is nil)" do
      # Create test data without optional parameters
      initiator_random = Bytes.new(32, 0xDD_u8)
      responder_random = Bytes.new(32, 0xEE_u8)
      responder_session_id = 5678_u16

      # Create response without nested parameters
      response = NestedValueTest::PbkdfResponse.new(
        initiator_random: initiator_random,
        responder_random: responder_random,
        responder_session_id: responder_session_id
      )

      # Verify optional field is nil
      response.pbkdf_parameters.should be_nil

      # Encode to TLV bytes
      encoded = response.to_slice

      # Decode from TLV bytes
      decoded = NestedValueTest::PbkdfResponse.new(encoded)

      # Verify all fields
      decoded.initiator_random.should eq(initiator_random)
      decoded.responder_random.should eq(responder_random)
      decoded.responder_session_id.should eq(responder_session_id)
      decoded.pbkdf_parameters.should be_nil
    end
  end

  describe "SimpleNestedValue with TLV::Value metadata" do
    it "encodes and decodes with hash metadata" do
      metadata = {
        0_u8 => "name",
        1_u8 => 42_u32,
      } of TLV::Tag => TLV::Value

      simple = NestedValueTest::SimpleNestedValue.new(id: 123_u16, metadata: metadata)

      # Encode and decode
      encoded = simple.to_slice
      decoded = NestedValueTest::SimpleNestedValue.new(encoded)

      decoded.id.should eq(123_u16)
      decoded.metadata.should_not be_nil
      decoded.metadata.should eq(metadata)
    end

    it "encodes and decodes with array metadata" do
      metadata = [1_u32, 2_u32, 3_u32] of TLV::Value

      simple = NestedValueTest::SimpleNestedValue.new(id: 456_u16, metadata: metadata)

      # Encode and decode
      encoded = simple.to_slice
      decoded = NestedValueTest::SimpleNestedValue.new(encoded)

      decoded.id.should eq(456_u16)
      decoded.metadata.should_not be_nil
      decoded.metadata.should eq(metadata)
    end

    it "encodes and decodes with primitive metadata" do
      metadata : TLV::Value = "test_value"

      simple = NestedValueTest::SimpleNestedValue.new(id: 789_u16, metadata: metadata)

      # Encode and decode
      encoded = simple.to_slice
      decoded = NestedValueTest::SimpleNestedValue.new(encoded)

      decoded.id.should eq(789_u16)
      decoded.metadata.should_not be_nil
      decoded.metadata.should eq(metadata)
    end

    it "encodes and decodes without metadata (optional)" do
      simple = NestedValueTest::SimpleNestedValue.new(id: 999_u16)

      # Encode and decode
      encoded = simple.to_slice
      decoded = NestedValueTest::SimpleNestedValue.new(encoded)

      decoded.id.should eq(999_u16)
      decoded.metadata.should be_nil
    end
  end
end
