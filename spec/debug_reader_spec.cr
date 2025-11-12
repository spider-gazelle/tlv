require "./spec_helper"

describe "Debug Reader Output" do
  it "shows what Reader.get returns for our test case" do
    # Test data: iPhone's pA from Pake1 message
    ec_point = Bytes[
      0x04, 0x11, 0x28, 0xc3, 0xa4, 0x6f, 0xa1, 0xdf, 0x0a, 0x15, 0x1d, 0xbc, 0x9a, 0x85, 0xb0, 0x0d,
      0xa9, 0x64, 0x89, 0x98, 0x0d, 0xd6, 0x14, 0x38, 0x13, 0x4e, 0x76, 0x40, 0xec, 0x4e, 0x78, 0xad,
      0xcb, 0x7d, 0xd8, 0xed, 0x44, 0x23, 0xfc, 0xea, 0x5e, 0x34, 0xed, 0x2e, 0x16, 0xdf, 0x69, 0xb1,
      0xcb, 0x29, 0xd5, 0xe6, 0x72, 0x19, 0x6b, 0x24, 0xfd, 0xc5, 0x27, 0xcb, 0x21, 0xad, 0x4b, 0xfe,
      0xee,
    ]

    full_tlv = Bytes[
      0x15,                    # Anonymous structure
      0x30, 0x01, 0x41,        # Tag 1 (context), length 65
    ] + ec_point + Bytes[0x18] # EC point + end marker

    # Create a Reader and see what it returns
    reader = TLV::Reader.new(full_tlv)
    result = reader.get

    puts "\n=== Reader.get returned ==="
    puts "Type: #{result.class}"
    puts "Value: #{result.inspect}"

    if result.is_a?(Hash)
      puts "\nKeys: #{result.keys.inspect}"
      result.each do |key, value|
        puts "\nKey: #{key.inspect}"
        puts "  Value type: #{value.class}"
        if value.is_a?(Hash)
          puts "  Value keys: #{value.keys.inspect}"
          value.each do |subkey, subvalue|
            puts "    Subkey: #{subkey.inspect}"
            puts "    Subvalue type: #{subvalue.class}"
            if subvalue.is_a?(Bytes)
              puts "    Subvalue size: #{subvalue.size}"
              puts "    Subvalue first 10 bytes: #{subvalue[0, [10, subvalue.size].min].to_a.inspect}"
            else
              puts "    Subvalue: #{subvalue.inspect}"
            end
          end
        elsif value.is_a?(Bytes)
          puts "  Value size: #{value.size}"
          puts "  Value first 10 bytes: #{value[0, [10, value.size].min].to_a.inspect}"
        else
          puts "  Value: #{value.inspect}"
        end
      end
    end

    # This test is just for debugging - always pass
    true.should eq(true)
  end
end
