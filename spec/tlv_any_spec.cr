require "./spec_helper"

# Ported from matter.js TlvAnyTest.ts
# Tests TLV Any encoding/decoding - generic TLV decoding
describe "TLV Any" do
  # Test vectors from matter.js TlvAnyTest.ts
  describe "encode/decode" do
    it "encodes and decodes null" do
      # "14" => null
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put_null(nil)

      encoded = io.to_slice
      encoded.hexstring.should eq("14")

      reader = TLV::Reader.new(encoded)
      result = reader.get
      result["Any"].should be_nil
    end

    it "encodes and decodes empty array" do
      # "1618" => []
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_array(nil)
      writer.end_container

      encoded = io.to_slice
      encoded.hexstring.should eq("1618")

      reader = TLV::Reader.new(encoded)
      result = reader.get
      result["Any"].as(Array).size.should eq(0)
    end

    it "calculates byte size for null" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put_null(nil)

      io.to_slice.size.should eq(1) # "14" is 1 byte
    end

    it "calculates byte size for empty array" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_array(nil)
      writer.end_container

      io.to_slice.size.should eq(2) # "1618" is 2 bytes
    end
  end

  describe "generic decoding" do
    it "decodes a boolean true" do
      # 0x09 = true
      reader = TLV::Reader.new("09".hexbytes)
      result = reader.get
      result["Any"].should eq(true)
    end

    it "decodes a boolean false" do
      # 0x08 = false
      reader = TLV::Reader.new("08".hexbytes)
      result = reader.get
      result["Any"].should eq(false)
    end

    it "decodes a null" do
      # 0x14 = null
      reader = TLV::Reader.new("14".hexbytes)
      result = reader.get
      result["Any"].should be_nil
    end

    it "decodes an array of integers" do
      # Array: [1, 2]
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_array(nil)
      writer.put(nil, 1_u64)
      writer.put(nil, 2_u64)
      writer.end_container

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      arr = result["Any"].as(Array)
      arr.size.should eq(2)
      arr[0].should eq(1_u8)
      arr[1].should eq(2_u8)
    end

    it "decodes a list of strings" do
      # Array of strings: ["a", "b"]
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_array(nil)
      writer.put(nil, "a")
      writer.put(nil, "b")
      writer.end_container

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      arr = result["Any"].as(Array)
      arr.size.should eq(2)
      arr[0].should eq("a")
      arr[1].should eq("b")
    end

    it "decodes a structure" do
      # Structure: { 1: "a", 2: "b" }
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      structure = {
        1_u8 => "a",
        2_u8 => "b",
      } of TLV::Tag => TLV::Value
      writer.put(nil, structure)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      struct_result = result["Any"].as(Hash)
      struct_result[1_u8].should eq("a")
      struct_result[2_u8].should eq("b")
    end

    it "decodes an array of structures" do
      # Array of structures: [{ 1: "a", 2: "b" }, { 3: "c", 4: "d" }]
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_array(nil)

      # First structure
      writer.start_structure(nil)
      writer.put(1_u8, "a")
      writer.put(2_u8, "b")
      writer.end_container

      # Second structure
      writer.start_structure(nil)
      writer.put(3_u8, "c")
      writer.put(4_u8, "d")
      writer.end_container

      writer.end_container

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      arr = result["Any"].as(Array)
      arr.size.should eq(2)

      first = arr[0].as(Hash)
      first[1_u8].should eq("a")
      first[2_u8].should eq("b")

      second = arr[1].as(Hash)
      second[3_u8].should eq("c")
      second[4_u8].should eq("d")
    end

    it "decodes unsigned integers of various sizes" do
      # UInt8
      reader = TLV::Reader.new("0401".hexbytes) # 0x04 + 01
      result = reader.get
      result["Any"].should eq(1_u8)

      # UInt16
      reader = TLV::Reader.new("050001".hexbytes) # 0x05 + 0100 (LE)
      result = reader.get
      result["Any"].should eq(256_u16)

      # UInt32
      reader = TLV::Reader.new("0600010000".hexbytes) # 0x06 + 00010000 (LE)
      result = reader.get
      result["Any"].should eq(256_u32)
    end

    it "decodes signed integers" do
      # Int8 = -1
      reader = TLV::Reader.new("00ff".hexbytes) # 0x00 + ff
      result = reader.get
      result["Any"].should eq(-1_i8)
    end

    it "decodes float32" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, 3.14_f32)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result["Any"].as(Float32).should be_close(3.14_f32, 0.001)
    end

    it "decodes float64" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, 3.14159265359_f64)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result["Any"].as(Float64).should be_close(3.14159265359_f64, 0.0000001)
    end

    it "decodes byte string" do
      # ByteString: [0x00, 0x01, 0x02]
      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, Bytes[0x00, 0x01, 0x02])

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get
      result["Any"].as(Slice(UInt8)).should eq(Bytes[0x00, 0x01, 0x02])
    end
  end

  describe "round-trip encoding" do
    it "round-trips a complex structure" do
      original = {
        1_u8 => 42_u64,
        2_u8 => "hello",
        3_u8 => true,
        4_u8 => Bytes[1, 2, 3],
      } of TLV::Tag => TLV::Value

      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, original)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get.as(Hash)["Any"].as(Hash)

      result[1_u8].should eq(42_u8)
      result[2_u8].should eq("hello")
      result[3_u8].should eq(true)
      result[4_u8].as(Slice(UInt8)).should eq(Bytes[1, 2, 3])
    end
  end
end
