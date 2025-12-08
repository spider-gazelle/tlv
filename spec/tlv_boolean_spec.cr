require "./spec_helper"

# Ported from matter.js TlvBooleanTest.ts
# Tests TLV boolean encoding/decoding compatibility
describe "TLV Boolean" do
  # Test vectors from matter.js
  # true: encoded "09"
  # false: encoded "08"

  describe "encode" do
    it "encodes true" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, true)
      io.to_slice.hexstring.should eq("09")
    end

    it "encodes false" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, false)
      io.to_slice.hexstring.should eq("08")
    end
  end

  describe "decode" do
    it "decodes true" do
      bytes = "09".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get
      result.as(Hash)["Any"].should eq(true)
    end

    it "decodes false" do
      bytes = "08".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get
      result.as(Hash)["Any"].should eq(false)
    end
  end

  describe "calculate byte length" do
    it "calculates byte length for true" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, true)
      io.to_slice.size.should eq(1)
    end

    it "calculates byte length for false" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, false)
      io.to_slice.size.should eq(1)
    end
  end

  describe "round-trip" do
    it "round-trips true" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, true)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].should eq(true)
    end

    it "round-trips false" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, false)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].should eq(false)
    end
  end
end
