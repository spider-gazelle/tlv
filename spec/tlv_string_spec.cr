require "./spec_helper"

# Ported from matter.js TlvStringTest.ts
# Tests TLV string encoding/decoding compatibility
describe "TLV String" do
  describe "encode" do
    it "encodes a string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "test")
      io.to_slice.hexstring.should eq("0c0474657374")
    end

    it "encodes a string that gets utf8 encoded" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "testè")
      io.to_slice.hexstring.should eq("0c0674657374c3a8")
    end
  end

  describe "decode" do
    it "decodes a string" do
      bytes = "0c0474657374".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get
      result.as(Hash)["Any"].should eq("test")
    end

    it "decodes a string that was utf8" do
      bytes = "0c0674657374c3a8".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get
      result.as(Hash)["Any"].should eq("testè")
    end
  end

  describe "calculate byte size" do
    it "calculates byte size for a string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "test")
      io.to_slice.size.should eq(6)
    end

    it "calculates byte size for a utf8 string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "testè")
      io.to_slice.size.should eq(8)
    end
  end

  describe "round-trip" do
    it "round-trips a simple string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "hello world")

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].should eq("hello world")
    end

    it "round-trips a utf8 string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "héllo wörld")

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].should eq("héllo wörld")
    end

    it "round-trips an empty string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "")

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].should eq("")
    end
  end
end

describe "TLV ByteString" do
  describe "encode" do
    it "encodes a byte string" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, "0001".hexbytes)
      io.to_slice.hexstring.should eq("10020001")
    end
  end

  describe "decode" do
    it "decodes a byte string" do
      bytes = "10020001".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get
      result.as(Hash)["Any"].as(Slice(UInt8)).hexstring.should eq("0001")
    end
  end

  describe "round-trip" do
    it "round-trips a byte string" do
      original = "0102030405060708".hexbytes
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, original)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].as(Slice(UInt8)).should eq(original)
    end

    it "round-trips an empty byte string" do
      original = Bytes.new(0)
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, original)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result.as(Hash)["Any"].as(Slice(UInt8)).should eq(original)
    end
  end
end
