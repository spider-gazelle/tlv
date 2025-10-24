require "./spec_helper"

describe "TLV UInt encoding bug" do
  it "encodes UInt8 without duplication" do
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.put(nil, 1_u8)

    # Should be: 04 01 (type=04 for 1-byte uint, value=01)
    # Bug produces: 04 01 00 01 (encodes twice: as UInt8 and as Int)
    result = io.to_slice.hexstring
    result.should eq("0401")
  end

  it "encodes UInt16 without duplication" do
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.put(nil, 0x0100_u16)

    # Should be: 05 00 01 (type=05 for 2-byte uint, value=0x0100 little-endian)
    result = io.to_slice.hexstring
    result.should eq("050001")
  end

  it "encodes UInt32 without duplication" do
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.put(nil, 0x01000000_u32)

    # Should be: 06 00 00 00 01 (type=06 for 4-byte uint)
    result = io.to_slice.hexstring
    result.should eq("0600000001")
  end

  it "encodes UInt64 without duplication" do
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.put(nil, 0x01000000000000_u64)

    # Should be: 07 00 00 00 00 00 00 01 00 (type=07 for 8-byte uint)
    result = io.to_slice.hexstring
    result.should eq("070000000000000100")
  end

  it "encodes signed int correctly" do
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.put(nil, -1)

    # Should be: 00 ff (type=00 for 1-byte int, value=-1)
    result = io.to_slice.hexstring
    result.should eq("00ff")
  end

  it "encodes positive signed int correctly" do
    io = IO::Memory.new
    writer = TLV::Writer.new(io)
    writer.put(nil, 256)

    # Should be: 01 00 01 (type=01 for 2-byte int, value=256)
    result = io.to_slice.hexstring
    result.should eq("010001")
  end
end
