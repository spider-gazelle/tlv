require "./spec_helper"

# Test that PATH container type is preserved during encode/decode cycles
describe "PATH Container Type Preservation" do
  it "preserves PATH container when encoding structure containing PATH" do
    # Build a PATH container with tagged elements
    path_io = IO::Memory.new
    path_writer = TLV::Writer.new(path_io)
    path_writer.start_path(nil)
    path_writer.put(2_u8, 0_u16)  # endpoint
    path_writer.put(3_u8, 40_u32) # cluster
    path_writer.put(4_u8, 9_u32)  # attribute
    path_writer.end_container
    path_bytes = path_io.rewind.to_slice

    puts "\n=== Original PATH bytes ==="
    puts "Hex: #{path_bytes.hexstring}"
    puts "Byte 0: 0x#{path_bytes[0].to_s(16)} (should be 0x17 = PATH)"
    path_bytes[0].should eq 0x17_u8

    # Decode the PATH
    path_reader = TLV::Reader.new(path_bytes)
    path_value = path_reader.get["Any"]

    puts "\n=== Decoded PATH value ==="
    puts "Type: #{path_value.class}"
    puts "Value: #{path_value.inspect[0, 80]}"

    # Now put it in a structure and re-encode
    structure = {
      1_u8 => path_value, # Put the decoded PATH value into a structure
    } of TLV::Tag => TLV::Value

    # Re-encode
    reencoded_io = IO::Memory.new
    reencoded_writer = TLV::Writer.new(reencoded_io)
    reencoded_writer.put(nil, structure)
    reencoded_bytes = reencoded_io.rewind.to_slice

    puts "\n=== Re-encoded structure with PATH ==="
    puts "Hex: #{reencoded_bytes.hexstring}"

    # Decode to check what we got
    reenc_reader = TLV::Reader.new(reencoded_bytes)
    reenc_data = reenc_reader.get
    reenc_root = reenc_data.as(Hash)["Any"].as(Hash)
    reenc_path = reenc_root[1_u8]

    puts "\n=== Re-encoded PATH check ==="
    puts "Type: #{reenc_path.class}"
    reenc_path.should be_a(TLV::PathContainer)

    # The path should still be encoded as PATH (0x17)
    # Let's check by looking at the raw bytes
    # Structure layout: [structure_start][context_tag_control+type][tag_value][path_contents][end][end]
    # Position 0: 0x15 (structure start)
    # Position 1: 0x3X (control byte: context tag + container type in lower 5 bits)
    # Position 2: 0x01 (tag value)

    # Check control byte of the path element
    path_control_byte_pos = 1 # Position after structure start
    if reencoded_bytes.size > path_control_byte_pos
      control_byte = reencoded_bytes[path_control_byte_pos]
      container_type = control_byte & 0x1F
      tag_control = (control_byte & 0xE0) >> 5

      puts "Control byte at position #{path_control_byte_pos}: 0x#{control_byte.to_s(16)}"
      puts "Tag control (bits 5-7): #{tag_control} (1 = context-specific)"
      puts "Container type (bits 0-4): 0x#{container_type.to_s(16)}"

      if container_type == 0x17
        puts "✅ PATH container type PRESERVED!"
        container_type.should eq(0x17)
      elsif container_type == 0x16
        puts "❌ PATH converted to ARRAY (0x16)"
        puts "This is why chip-tool can't parse our responses!"
        fail "PATH container type not preserved - converted to ARRAY"
      else
        puts "❌ Unexpected container type: 0x#{container_type.to_s(16)}"
        fail "PATH container type not preserved - got unexpected type 0x#{container_type.to_s(16)}"
      end
    end
  end
end
