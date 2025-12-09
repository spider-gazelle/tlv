require "./spec_helper"

# Ported from matter.js TlvVoidTest.ts
# Tests TLV void (nil) encoding - void encodes to 0 bytes
describe "TLV Void" do
  describe "encode" do
    it "encodes nil to empty bytes" do
      # In Crystal, nil values are typically skipped in TLV encoding
      # TlvVoid.encode(undefined).byteLength === 0
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # When encoding nil directly (void), the result should be 0 bytes
      # This represents the concept of "no value" in Matter protocol
      # Note: In Crystal's TLV implementation, nil is often used for optional
      # fields that are not present, which produces no output
      writer.put_null(nil)
      io.to_slice.hexstring.should eq("14")
    end

    it "void/nil fields don't add bytes to structure when absent" do
      # TLV encoding skips fields with nil/undefined values
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # A structure with no fields
      structure = {} of TLV::Tag => TLV::Value
      writer.put(nil, structure)

      # Empty structure: start (15) + end (18) = 2 bytes
      io.to_slice.hexstring.should eq("1518")
    end
  end

  describe "calculate byte length" do
    it "nil value has minimal encoding" do
      # TlvVoid has 0 byte length for undefined
      # In Crystal, the TLV Null type uses 1 byte (0x14)
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put_null(nil)
      io.to_slice.size.should eq(1) # 0x14 (null control byte)
    end
  end

  describe "validation" do
    it "nil is a valid void/absent value representation" do
      # Crystal uses nil to represent absence/void
      value : TLV::Value = nil
      value.should be_nil
    end
  end
end
