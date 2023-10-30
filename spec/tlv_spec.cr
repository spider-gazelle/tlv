require "./spec_helper"

describe TLV do
  it "encodes and decodes values" do
    io = IO::Memory.new

    writer = TLV::Writer.new(io)

    input = {
                 1 => Id::A.value,
                 2 => 65535,
                 3 => true,
                 4 => nil,
                 5 => "Hello, World!",
                 6 => "Good morning!".to_slice,
                 7 => [1, 2, 3, 4, 5, "Bye, World!", true, false] of TLV::Value,
                 8 => {1 => 1_u32, 2 => "UTF-8 კოდირების ტესტი", {nil, 1} => [1, 2, 3, 4, { {100, 100} => "你好" } of TLV::Tag => TLV::Value] of TLV::Value, {nil, 2} => {1 => "Giorgi", 2 => "Kavrelishvili"} of TLV::Tag => TLV::Value} of TLV::Tag => TLV::Value,
      {0x235A, 42} => "FOO",
      {nil, 42}    => "BAR",
    } of TLV::Tag => TLV::Value

    writer.put(nil, input)

    data = io.rewind.to_slice

    reader = TLV::Reader.new(data)

    pp reader.get

    # Parse the data into packet
    first = Packet.new(data)

    # Re-parse packet data into a new packet
    second = Packet.new(first.to_slice)

    first.to_slice.should eq second.to_slice
  end
end
