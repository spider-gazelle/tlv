require "./spec_helper"

# Test that empty arrays are properly encoded as TLV arrays (not zero bytes)
describe "TLV Empty Array Encoding" do
  describe "Array(Hash(Tag, Value))" do
    it "encodes empty array of hashes correctly" do
      empty_array = [] of Hash(TLV::Tag, TLV::Value)

      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, empty_array)

      result = io.to_slice

      # Should produce 2 bytes: array start (0x16) + end container (0x18)
      result.size.should eq(2)
      result[0].should eq(0x16_u8) # Anonymous array
      result[1].should eq(0x18_u8) # End of container
    end

    it "encodes empty array of hashes with context-specific tag" do
      empty_array = [] of Hash(TLV::Tag, TLV::Value)

      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.start_structure(nil)
      writer.put(1_u8, empty_array)
      writer.end_container

      result = io.to_slice

      # Structure: 0x15 (anon struct)
      # Array: 0x36 (context tag array) + 0x01 (tag 1)
      # End array: 0x18
      # End struct: 0x18
      result.size.should eq(5)
      result[0].should eq(0x15_u8) # Anonymous structure
      result[1].should eq(0x36_u8) # Context-specific array
      result[2].should eq(0x01_u8) # Tag 1
      result[3].should eq(0x18_u8) # End of array
      result[4].should eq(0x18_u8) # End of structure
    end

    it "encodes non-empty array of hashes correctly" do
      array = [
        {0_u8 => 123_u32, 1_u8 => "test"} of TLV::Tag => TLV::Value,
      ]

      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, array)

      result = io.to_slice

      # Should start with array marker and end with end container
      result[0].should eq(0x16_u8)   # Anonymous array
      result.last.should eq(0x18_u8) # End of container

      # Verify we can decode it back
      reader = TLV::Reader.new(result)
      decoded = reader.get.as(Hash)["Any"].as(Array)
      decoded.size.should eq(1)
      decoded[0].as(Hash)[0_u8].should eq(123_u32)
    end

    it "round-trips empty array correctly" do
      empty_array = [] of Hash(TLV::Tag, TLV::Value)

      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, empty_array)

      result = io.to_slice

      # Decode and verify
      reader = TLV::Reader.new(result)
      decoded = reader.get.as(Hash)["Any"].as(Array)
      decoded.size.should eq(0)
      decoded.empty?.should be_true
    end
  end

  describe "Array(Value)" do
    it "encodes empty Array(Value) correctly" do
      empty_array = [] of TLV::Value

      io = IO::Memory.new
      writer = TLV::Writer.new(io)
      writer.put(nil, empty_array)

      result = io.to_slice

      # Should produce 2 bytes: array start (0x16) + end container (0x18)
      result.size.should eq(2)
      result[0].should eq(0x16_u8) # Anonymous array
      result[1].should eq(0x18_u8) # End of container
    end
  end

  describe "explicit start_array/end_container" do
    it "produces same output as put for empty array" do
      # Method 1: Using put
      io1 = IO::Memory.new
      writer1 = TLV::Writer.new(io1)
      writer1.put(nil, [] of Hash(TLV::Tag, TLV::Value))
      result1 = io1.to_slice

      # Method 2: Using explicit start_array/end_container
      io2 = IO::Memory.new
      writer2 = TLV::Writer.new(io2)
      writer2.start_array(nil)
      writer2.end_container
      result2 = io2.to_slice

      # Both should produce identical output
      result1.should eq(result2)
    end
  end
end
