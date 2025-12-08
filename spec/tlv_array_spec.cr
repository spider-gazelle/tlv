require "./spec_helper"

# Ported from matter.js TlvArrayTest.ts
# Tests TLV array encoding/decoding compatibility
describe "TLV Array" do
  describe "encode" do
    it "encodes an array of strings" do
      # Test vector from matter.js: ["a", "b", "c"] -> "160c01610c01620c016318"
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      values = ["a", "b", "c"] of TLV::Value
      writer.put(nil, values)

      io.to_slice.hexstring.should eq("160c01610c01620c016318")
    end

    it "encodes an empty array" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      values = [] of TLV::Value
      writer.put(nil, values)

      io.to_slice.hexstring.should eq("1618")
    end

    it "encodes an array of integers" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      values = [1_u64, 2_u64, 3_u64] of TLV::Value
      writer.put(nil, values)

      # Array (16) with uint8 elements (04 01, 04 02, 04 03) + end of container (18)
      io.to_slice.hexstring.should eq("1604010402040318")
    end
  end

  describe "decode" do
    it "decodes an array of strings" do
      bytes = "160c01610c01620c016318".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get

      # Result should be hash with "Any" key containing array
      arr = result.as(Hash)["Any"].as(Array)
      arr.size.should eq(3)
      arr[0].should eq("a")
      arr[1].should eq("b")
      arr[2].should eq("c")
    end

    it "decodes an empty array" do
      bytes = "1618".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get

      arr = result.as(Hash)["Any"].as(Array)
      arr.size.should eq(0)
    end

    it "decodes an array of integers" do
      bytes = "1604010402040318".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get

      arr = result.as(Hash)["Any"].as(Array)
      arr.size.should eq(3)
      arr[0].should eq(1_u8)
      arr[1].should eq(2_u8)
      arr[2].should eq(3_u8)
    end
  end

  describe "calculate byte length" do
    it "calculates byte length for array of strings" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      values = ["a", "b", "c"] of TLV::Value
      writer.put(nil, values)

      io.to_slice.size.should eq(11)
    end
  end

  describe "round-trip" do
    it "round-trips an array of strings" do
      original = ["hello", "world", "test"] of TLV::Value
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, original)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get

      arr = result.as(Hash)["Any"].as(Array)
      arr.size.should eq(3)
      arr[0].should eq("hello")
      arr[1].should eq("world")
      arr[2].should eq("test")
    end

    it "round-trips a nested array within structure" do
      # Create a structure with an array field
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      structure = {
        1_u8 => ["a", "b"] of TLV::Value,
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get.as(Hash)["Any"].as(Hash)

      arr = result[1_u8].as(Array)
      arr.size.should eq(2)
      arr[0].should eq("a")
      arr[1].should eq("b")
    end
  end
end
