require "./spec_helper"

# Ported from matter.js TlvComplexTest.ts
# Tests complex TLV object encoding/decoding with nested structures
describe "TLV Complex" do
  # Test vectors from matter.js TlvComplexTest.ts

  describe "an object with all fields" do
    # Original data:
    # {
    #   arrayField: [
    #     { mandatoryNumber: 1, optionalByteString: Bytes[0x00, 0x00, 0x00] },
    #     { mandatoryNumber: 2, optionalByteString: Bytes[0x99, 0x99, 0x99] },
    #   ],
    #   optionalString: "test",
    #   nullableBoolean: true,
    #   optionalWrapperBigInt: FabricId(1n),
    #   optionalWrapperNumber: FabricIndex(2),
    # }
    # Encoded: "15360115240101300203000000181524010230020399999918182c020474657374290324040124050218"

    expected_hex = "15360115240101300203000000181524010230020399999918182c020474657374290324040124050218"

    it "encodes a complex object with all fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.start_structure(nil)

      # arrayField (tag 1)
      writer.start_array(1_u8)

      # First array element: { mandatoryNumber: 1, optionalByteString: 0x000000 }
      writer.start_structure(nil)
      writer.put(1_u8, 1_u64)                   # mandatoryNumber
      writer.put(2_u8, Bytes[0x00, 0x00, 0x00]) # optionalByteString
      writer.end_container

      # Second array element: { mandatoryNumber: 2, optionalByteString: 0x999999 }
      writer.start_structure(nil)
      writer.put(1_u8, 2_u64)                   # mandatoryNumber
      writer.put(2_u8, Bytes[0x99, 0x99, 0x99]) # optionalByteString
      writer.end_container

      writer.end_container # end arrayField

      # optionalString (tag 2)
      writer.put(2_u8, "test")

      # nullableBoolean (tag 3)
      writer.put(3_u8, true)

      # optionalWrapperBigInt (tag 4) - FabricId(1)
      writer.put(4_u8, 1_u64)

      # optionalWrapperNumber (tag 5) - FabricIndex(2)
      writer.put(5_u8, 2_u64)

      writer.end_container # end structure

      io.to_slice.hexstring.should eq(expected_hex)
    end

    it "decodes a complex object with all fields" do
      reader = TLV::Reader.new(expected_hex.hexbytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      # Check arrayField (tag 1)
      array_field = result[1_u8].as(Array)
      array_field.size.should eq(2)

      first = array_field[0].as(Hash)
      first[1_u8].should eq(1_u8) # mandatoryNumber
      first[2_u8].as(Slice(UInt8)).should eq(Bytes[0x00, 0x00, 0x00])

      second = array_field[1].as(Hash)
      second[1_u8].should eq(2_u8)
      second[2_u8].as(Slice(UInt8)).should eq(Bytes[0x99, 0x99, 0x99])

      # Check optionalString (tag 2)
      result[2_u8].should eq("test")

      # Check nullableBoolean (tag 3)
      result[3_u8].should eq(true)

      # Check optionalWrapperBigInt (tag 4)
      result[4_u8].should eq(1_u8)

      # Check optionalWrapperNumber (tag 5)
      result[5_u8].should eq(2_u8)
    end

    it "calculates correct byte length" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.start_structure(nil)
      writer.start_array(1_u8)
      writer.start_structure(nil)
      writer.put(1_u8, 1_u64)
      writer.put(2_u8, Bytes[0x00, 0x00, 0x00])
      writer.end_container
      writer.start_structure(nil)
      writer.put(1_u8, 2_u64)
      writer.put(2_u8, Bytes[0x99, 0x99, 0x99])
      writer.end_container
      writer.end_container
      writer.put(2_u8, "test")
      writer.put(3_u8, true)
      writer.put(4_u8, 1_u64)
      writer.put(5_u8, 2_u64)
      writer.end_container

      io.to_slice.size.should eq(expected_hex.size // 2)
    end
  end

  describe "an object with minimum fields" do
    # Original data:
    # {
    #   arrayField: [{ mandatoryNumber: 1 }],
    #   nullableBoolean: null,
    # }
    # Encoded: "153601152401011818340318"

    expected_hex = "153601152401011818340318"

    it "encodes an object with minimum fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.start_structure(nil)

      # arrayField (tag 1)
      writer.start_array(1_u8)
      writer.start_structure(nil)
      writer.put(1_u8, 1_u64) # mandatoryNumber
      writer.end_container
      writer.end_container

      # nullableBoolean (tag 3) - null
      writer.put_null(3_u8)

      writer.end_container

      io.to_slice.hexstring.should eq(expected_hex)
    end

    it "decodes an object with minimum fields" do
      reader = TLV::Reader.new(expected_hex.hexbytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      # Check arrayField (tag 1)
      array_field = result[1_u8].as(Array)
      array_field.size.should eq(1)

      first = array_field[0].as(Hash)
      first[1_u8].should eq(1_u8)

      # Check nullableBoolean (tag 3) - should be null
      result[3_u8].should be_nil
    end
  end

  describe "an object without wrapper fields" do
    # Original data (without optionalWrapperBigInt and optionalWrapperNumber):
    # Encoded: "15360115240101300203000000181524010230020399999918182c020474657374290318"

    expected_hex = "15360115240101300203000000181524010230020399999918182c020474657374290318"

    it "encodes an object without wrapper fields" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.start_structure(nil)

      # arrayField (tag 1)
      writer.start_array(1_u8)

      writer.start_structure(nil)
      writer.put(1_u8, 1_u64)
      writer.put(2_u8, Bytes[0x00, 0x00, 0x00])
      writer.end_container

      writer.start_structure(nil)
      writer.put(1_u8, 2_u64)
      writer.put(2_u8, Bytes[0x99, 0x99, 0x99])
      writer.end_container

      writer.end_container

      # optionalString (tag 2)
      writer.put(2_u8, "test")

      # nullableBoolean (tag 3)
      writer.put(3_u8, true)

      writer.end_container

      io.to_slice.hexstring.should eq(expected_hex)
    end

    it "decodes an object without wrapper fields" do
      reader = TLV::Reader.new(expected_hex.hexbytes)
      result = reader.get.as(Hash)["Any"].as(Hash)

      # Check arrayField
      array_field = result[1_u8].as(Array)
      array_field.size.should eq(2)

      # Check optionalString
      result[2_u8].should eq("test")

      # Check nullableBoolean
      result[3_u8].should eq(true)

      # Tags 4 and 5 should not exist
      result.has_key?(4_u8).should eq(false)
      result.has_key?(5_u8).should eq(false)
    end
  end

  describe "round-trip encoding" do
    it "round-trips a complex nested structure" do
      # Create a complex structure
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.start_structure(nil)

      # Nested array of structures
      writer.start_array(1_u8)
      3.times do |i|
        writer.start_structure(nil)
        writer.put(1_u8, (i + 1).to_u64)
        writer.put(2_u8, "item#{i}")
        writer.end_container
      end
      writer.end_container

      # Optional fields
      writer.put(2_u8, "description")
      writer.put(3_u8, false)

      writer.end_container

      encoded = io.to_slice

      # Decode and verify
      reader = TLV::Reader.new(encoded)
      result = reader.get.as(Hash)["Any"].as(Hash)

      array_field = result[1_u8].as(Array)
      array_field.size.should eq(3)

      3.times do |i|
        item = array_field[i].as(Hash)
        item[1_u8].should eq((i + 1).to_u8)
        item[2_u8].should eq("item#{i}")
      end

      result[2_u8].should eq("description")
      result[3_u8].should eq(false)
    end

    it "round-trips deeply nested structures" do
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      # Create 3 levels of nesting
      writer.start_structure(nil)
      writer.put(1_u8, "level1")
      writer.start_structure(2_u8)
      writer.put(1_u8, "level2")
      writer.start_structure(2_u8)
      writer.put(1_u8, "level3")
      writer.put(2_u8, 42_u64)
      writer.end_container
      writer.end_container
      writer.end_container

      encoded = io.to_slice

      reader = TLV::Reader.new(encoded)
      result = reader.get.as(Hash)["Any"].as(Hash)

      result[1_u8].should eq("level1")

      level2 = result[2_u8].as(Hash)
      level2[1_u8].should eq("level2")

      level3 = level2[2_u8].as(Hash)
      level3[1_u8].should eq("level3")
      level3[2_u8].should eq(42_u8)
    end
  end
end
