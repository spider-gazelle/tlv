require "./spec_helper"

# Test structs for nullable types
module NullableTypeTest
  struct AllNullableTypes
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property bool_val : Bool?

    @[TLV::Field(tag: 1)]
    property int8_val : Int8?

    @[TLV::Field(tag: 2)]
    property int16_val : Int16?

    @[TLV::Field(tag: 3)]
    property int32_val : Int32?

    @[TLV::Field(tag: 4)]
    property int64_val : Int64?

    @[TLV::Field(tag: 5)]
    property uint8_val : UInt8?

    @[TLV::Field(tag: 6)]
    property uint16_val : UInt16?

    @[TLV::Field(tag: 7)]
    property uint32_val : UInt32?

    @[TLV::Field(tag: 8)]
    property uint64_val : UInt64?

    @[TLV::Field(tag: 9)]
    property float32_val : Float32?

    @[TLV::Field(tag: 10)]
    property float64_val : Float64?

    @[TLV::Field(tag: 11)]
    property string_val : String?

    @[TLV::Field(tag: 12)]
    property bytes_val : Slice(UInt8)?

    def initialize(
      @bool_val : Bool? = nil,
      @int8_val : Int8? = nil,
      @int16_val : Int16? = nil,
      @int32_val : Int32? = nil,
      @int64_val : Int64? = nil,
      @uint8_val : UInt8? = nil,
      @uint16_val : UInt16? = nil,
      @uint32_val : UInt32? = nil,
      @uint64_val : UInt64? = nil,
      @float32_val : Float32? = nil,
      @float64_val : Float64? = nil,
      @string_val : String? = nil,
      @bytes_val : Slice(UInt8)? = nil,
    )
    end
  end

  enum Status
    Idle   = 0
    Active = 1
    Error  = 2
  end

  struct WithNullableEnum
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property status : Status?

    def initialize(@status : Status? = nil)
    end
  end

  struct NestedStruct
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property value : UInt16

    def initialize(@value : UInt16)
    end
  end

  struct WithNullableNested
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property nested : NestedStruct?

    def initialize(@nested : NestedStruct? = nil)
    end
  end
end

describe TLV::Serializable do
  describe "Nullable primitive types" do
    it "serializes and deserializes Bool?" do
      # Test with true
      struct_true = NullableTypeTest::AllNullableTypes.new(bool_val: true)
      bytes_true = struct_true.to_slice
      parsed_true = NullableTypeTest::AllNullableTypes.new(bytes_true)
      parsed_true.bool_val.should eq(true)

      # Test with false
      struct_false = NullableTypeTest::AllNullableTypes.new(bool_val: false)
      bytes_false = struct_false.to_slice
      parsed_false = NullableTypeTest::AllNullableTypes.new(bytes_false)
      parsed_false.bool_val.should eq(false)

      # Test with nil
      struct_nil = NullableTypeTest::AllNullableTypes.new(bool_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.bool_val.should be_nil
    end

    it "serializes and deserializes Int8?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(int8_val: -42_i8)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.int8_val.should eq(-42_i8)

      struct_nil = NullableTypeTest::AllNullableTypes.new(int8_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.int8_val.should be_nil
    end

    it "serializes and deserializes Int16?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(int16_val: -1000_i16)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.int16_val.should eq(-1000_i16)

      struct_nil = NullableTypeTest::AllNullableTypes.new(int16_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.int16_val.should be_nil
    end

    it "serializes and deserializes Int32?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(int32_val: -100000_i32)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.int32_val.should eq(-100000_i32)

      struct_nil = NullableTypeTest::AllNullableTypes.new(int32_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.int32_val.should be_nil
    end

    it "serializes and deserializes Int64?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(int64_val: -9876543210_i64)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.int64_val.should eq(-9876543210_i64)

      struct_nil = NullableTypeTest::AllNullableTypes.new(int64_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.int64_val.should be_nil
    end

    it "serializes and deserializes UInt8?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(uint8_val: 200_u8)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.uint8_val.should eq(200_u8)

      struct_nil = NullableTypeTest::AllNullableTypes.new(uint8_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.uint8_val.should be_nil
    end

    it "serializes and deserializes UInt16?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(uint16_val: 50000_u16)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.uint16_val.should eq(50000_u16)

      struct_nil = NullableTypeTest::AllNullableTypes.new(uint16_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.uint16_val.should be_nil
    end

    it "serializes and deserializes UInt32?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(uint32_val: 3000000000_u32)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.uint32_val.should eq(3000000000_u32)

      struct_nil = NullableTypeTest::AllNullableTypes.new(uint32_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.uint32_val.should be_nil
    end

    it "serializes and deserializes UInt64?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(uint64_val: 9876543210987654321_u64)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.uint64_val.should eq(9876543210987654321_u64)

      struct_nil = NullableTypeTest::AllNullableTypes.new(uint64_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.uint64_val.should be_nil
    end

    it "serializes and deserializes Float32?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(float32_val: 3.14_f32)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.float32_val.should_not be_nil
      parsed.float32_val.not_nil!.should be_close(3.14_f32, 0.001)

      struct_nil = NullableTypeTest::AllNullableTypes.new(float32_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.float32_val.should be_nil
    end

    it "serializes and deserializes Float64?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(float64_val: 2.718281828)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.float64_val.should_not be_nil
      parsed.float64_val.not_nil!.should be_close(2.718281828, 0.000001)

      struct_nil = NullableTypeTest::AllNullableTypes.new(float64_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.float64_val.should be_nil
    end

    it "serializes and deserializes String?" do
      struct_with_val = NullableTypeTest::AllNullableTypes.new(string_val: "Hello TLV")
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.string_val.should eq("Hello TLV")

      struct_nil = NullableTypeTest::AllNullableTypes.new(string_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.string_val.should be_nil
    end

    it "serializes and deserializes Slice(UInt8)?" do
      test_bytes = Bytes[0x01, 0x02, 0x03, 0x04]
      struct_with_val = NullableTypeTest::AllNullableTypes.new(bytes_val: test_bytes)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.bytes_val.should eq(test_bytes)

      struct_nil = NullableTypeTest::AllNullableTypes.new(bytes_val: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::AllNullableTypes.new(bytes_nil)
      parsed_nil.bytes_val.should be_nil
    end

    it "handles multiple nullable fields with mixed nil and non-nil values" do
      struct_mixed = NullableTypeTest::AllNullableTypes.new(
        bool_val: true,
        int32_val: 42,
        uint8_val: nil,
        string_val: "test",
        float64_val: nil
      )
      bytes = struct_mixed.to_slice
      parsed = NullableTypeTest::AllNullableTypes.new(bytes)

      parsed.bool_val.should eq(true)
      parsed.int32_val.should eq(42)
      parsed.uint8_val.should be_nil
      parsed.string_val.should eq("test")
      parsed.float64_val.should be_nil
    end
  end

  describe "Nullable complex types" do
    it "serializes and deserializes nullable enum" do
      # With value
      struct_with_val = NullableTypeTest::WithNullableEnum.new(status: NullableTypeTest::Status::Active)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::WithNullableEnum.new(bytes)
      parsed.status.should eq(NullableTypeTest::Status::Active)

      # With nil
      struct_nil = NullableTypeTest::WithNullableEnum.new(status: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::WithNullableEnum.new(bytes_nil)
      parsed_nil.status.should be_nil
    end

    it "serializes and deserializes nullable nested struct" do
      # With value
      nested = NullableTypeTest::NestedStruct.new(value: 9999_u16)
      struct_with_val = NullableTypeTest::WithNullableNested.new(nested: nested)
      bytes = struct_with_val.to_slice
      parsed = NullableTypeTest::WithNullableNested.new(bytes)
      parsed.nested.should_not be_nil
      parsed.nested.not_nil!.value.should eq(9999_u16)

      # With nil
      struct_nil = NullableTypeTest::WithNullableNested.new(nested: nil)
      bytes_nil = struct_nil.to_slice
      parsed_nil = NullableTypeTest::WithNullableNested.new(bytes_nil)
      parsed_nil.nested.should be_nil
    end
  end

  describe "Manual TLV encoding of nullable types" do
    it "parses manually encoded Bool? from TLV" do
      # Manually encode a structure with a boolean
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_structure(nil)
      writer.put(0_u8, true) # bool_val with true
      writer.end_container
      bytes = io.rewind.to_slice

      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.bool_val.should eq(true)
    end

    it "parses manually encoded Int32? from TLV" do
      # Manually encode a structure with an int32
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_structure(nil)
      writer.put(3_u8, 12345) # int32_val
      writer.end_container
      bytes = io.rewind.to_slice

      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.int32_val.should eq(12345)
    end

    it "parses manually encoded String? from TLV" do
      # Manually encode a structure with a string
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_structure(nil)
      writer.put(11_u8, "manual") # string_val
      writer.end_container
      bytes = io.rewind.to_slice

      parsed = NullableTypeTest::AllNullableTypes.new(bytes)
      parsed.string_val.should eq("manual")
    end
  end
end
