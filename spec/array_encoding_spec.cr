require "./spec_helper"

# Test how TLV encodes array of hashes
describe "TLV Array Encoding" do
  it "encodes array containing hash with tag 1" do
    # This is what we're encoding: [{1 => {...}}]
    inner_hash = {
      1_u8 => {
        0_u8 => 123_u32,
        1_u8 => [1, 2, 3] of TLV::Value,
        2_u8 => true,
      } of TLV::Tag => TLV::Value,
    } of TLV::Tag => TLV::Value

    array = [inner_hash.as(TLV::Value)]

    # Encode - wrap in structure to allow context-specific tag
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.start_structure(nil)
    writer.put(1_u8, array) # Tag 1: attributeReports
    writer.end_container
    encoded = io.rewind.to_slice

    puts "\nEncoded array of hash:"
    puts "  Hex: #{encoded.hexstring}"
    puts "  First 10 bytes: #{encoded[0, [10, encoded.size].min].hexstring}"
    puts ""

    # Check control bytes
    puts "  Byte 0: 0x#{encoded[0].to_s(16)} (should be 0x36 for Array at tag 1)"
    puts "  Byte 1: 0x#{encoded[1].to_s(16)} (tag value)"
    puts "  Byte 2: 0x#{encoded[2].to_s(16)} (first element type)"

    # Decode to verify
    reader = TLV::Reader.new(encoded)
    decoded = reader.get
    puts "  Decoded: #{decoded.inspect[0, 100]}"

    # Should have same structure back (now wrapped in structure)
    root = decoded.as(Hash(TLV::Tag, TLV::Value))["Any"].as(Hash(TLV::Tag, TLV::Value))
    result = root[1_u8].as(Array(TLV::Value))
    result.size.should eq(1)

    elem = result[0].as(Hash(TLV::Tag, TLV::Value))
    elem[1_u8].is_a?(Hash).should be_true
  end
end
