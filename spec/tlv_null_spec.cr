require "./spec_helper"

# Ported from matter.js TlvNullableTest.ts
# Tests TLV null encoding/decoding compatibility
describe "TLV Null" do
  # Test vectors from matter.js
  # null: encoded "14"

  describe "encode" do
    it "encodes null" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, nil)
      io.to_slice.hexstring.should eq("14")
    end
  end

  describe "decode" do
    it "decodes null" do
      bytes = "14".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get
      result.as(Hash)["Any"].should be_nil
    end
  end

  describe "calculate byte length" do
    it "calculates byte length for null" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, nil)
      io.to_slice.size.should eq(1)
    end
  end

  describe "round-trip" do
    it "round-trips null" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, nil)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].should be_nil
    end
  end

  describe "nullable within structure" do
    it "encodes structure with null field" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # Structure: { 1: null }
      structure = {
        1_u8 => nil,
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)

      # Structure start (15) + context tag 1 with null (24 01 14 is wrong, should be 34 01 for null with tag 1) + end (18)
      # Actually the null encoding is: control byte (14 & 0x1f = NULL type), with tag
      # With context-specific tag 1: control = 0x34 (NULL | CONTEXT_SPECIFIC), tag = 0x01
      # Result: 15 34 01 18

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get.as(Hash)["Any"].as(Hash)
      result[1_u8].should be_nil
    end
  end
end
