require "./spec_helper"

# Ported from matter.js TlvObjectTest.ts and TlvSchemaTest.ts
# Tests TLV structure encoding/decoding compatibility
describe "TLV Structure" do
  # Test vectors from matter.js TlvObjectTest.ts
  # "an object with all fields": { mandatoryField: 1, optionalField: "test" }
  # encoded: "152401012c02047465737418"

  describe "encode" do
    it "encodes a structure with all fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      structure = {
        1_u8 => 1_u64,
        2_u8 => "test",
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)
      io.to_slice.hexstring.should eq("152401012c02047465737418")
    end

    it "encodes a structure without optional fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # { mandatoryField: 1 } encoded: "1524010118"
      structure = {
        1_u8 => 1_u64,
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)
      io.to_slice.hexstring.should eq("1524010118")
    end

    it "encodes an empty structure" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      structure = {} of TLV::Tag => TLV::Value
      writer.put(nil, structure)

      io.to_slice.hexstring.should eq("1518")
    end
  end

  describe "decode" do
    it "decodes a structure with all fields" do
      bytes = "152401012c02047465737418".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      result[1_u8].should eq(1_u8)
      result[2_u8].should eq("test")
    end

    it "decodes a structure without optional fields" do
      bytes = "1524010118".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      result[1_u8].should eq(1_u8)
      result.keys.size.should eq(1)
    end
  end

  describe "calculate byte length" do
    it "calculates byte length for structure with all fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      structure = {
        1_u8 => 1_u64,
        2_u8 => "test",
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)
      io.to_slice.size.should eq(12)
    end
  end

  describe "round-trip" do
    it "round-trips a structure" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      original = {
        1_u8 => 42_u64,
        2_u8 => "hello world",
        3_u8 => true,
      } of TLV::Tag => TLV::Value

      writer.put(nil, original)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get.as(Hash)["Any"].as(Hash)

      result[1_u8].should eq(42_u8)
      result[2_u8].should eq("hello world")
      result[3_u8].should eq(true)
    end
  end

  describe "nested structures" do
    # Test vector from matter.js TlvSchemaTest.ts:
    # "TlvObject: nested struct and array of struct"
    # tlv: "1535012c010574657374312c020574657374321835022c010574657374332c02057465737434183603152c0505746573743518152c0505746573743618152c05057465737437181818"

    it "encodes nested structure" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # { field1: "test1", field2: "test2" }
      nested = {
        1_u8 => "test1",
        2_u8 => "test2",
      } of TLV::Tag => TLV::Value

      structure = {
        1_u8 => nested,
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)

      reader = TLV::Reader.new(io.to_slice)
      result = reader.get.as(Hash)["Any"].as(Hash)

      inner = result[1_u8].as(Hash)
      inner[1_u8].should eq("test1")
      inner[2_u8].should eq("test2")
    end

    it "encodes structure with array field" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # { field1: ["a", "b", "c", "zzz"] }
      # from TlvSchemaTest.ts: "1536010c01610c01620c01630c037a7a7a1818"
      structure = {
        1_u8 => ["a", "b", "c", "zzz"] of TLV::Value,
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)
      io.to_slice.hexstring.should eq("1536010c01610c01620c01630c037a7a7a1818")
    end

    it "decodes structure with array field" do
      bytes = "1536010c01610c01620c01630c037a7a7a1818".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      arr = result[1_u8].as(Array)
      arr.size.should eq(4)
      arr[0].should eq("a")
      arr[1].should eq("b")
      arr[2].should eq("c")
      arr[3].should eq("zzz")
    end
  end

  describe "number fields from TlvSchemaTest" do
    # Test vector: "TlvObject: TlvNumber fields"
    # tlv: "152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118"
    # jsObj: fieldFloat: 6546.25390625, fieldDouble: 6546.254, fieldInt8: -1, etc.

    it "encodes structure with number fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      structure = {
         1_u8 => 6546.25390625_f32, # fieldFloat
         2_u8 => 6546.254_f64,      # fieldDouble
         3_u8 => -1,                # fieldInt8
         4_u8 => -1,                # fieldInt16 (fits in int8)
         5_u8 => -1,                # fieldInt32 (fits in int8)
         6_u8 => -1,                # fieldInt64 (fits in int8)
         7_u8 => 1_u64,             # fieldUInt8
         8_u8 => 1_u64,             # fieldUInt16 (fits in uint8)
         9_u8 => 1_u64,             # fieldUInt32 (fits in uint8)
        10_u8 => 1_u64,             # fieldUInt64 (fits in uint8)
      } of TLV::Tag => TLV::Value

      writer.put(nil, structure)
      io.to_slice.hexstring.should eq("152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118")
    end

    it "decodes structure with number fields" do
      bytes = "152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118".hexbytes
      reader = TLV::Reader.new(bytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      result[1_u8].as(Float32).should be_close(6546.25390625_f32, 0.001)
      result[2_u8].as(Float64).should be_close(6546.254_f64, 0.001)
      result[3_u8].should eq(-1_i8)
      result[4_u8].should eq(-1_i8)
      result[5_u8].should eq(-1_i8)
      result[6_u8].should eq(-1_i8)
      result[7_u8].should eq(1_u8)
      result[8_u8].should eq(1_u8)
      result[9_u8].should eq(1_u8)
      result[10_u8].should eq(1_u8)
    end
  end
end
