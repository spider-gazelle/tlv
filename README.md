# TLV

Matter TLV encoder/decoder

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tlv:
       github: spider-gazelle/tlv
   ```

2. Run `shards install`

## Usage

```crystal
require "tlv"

class Packet
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt8

  @[TLV::Field(tag: 2)]
  property port : UInt16

  @[TLV::Field(tag: 3)]
  property? duplex : Bool

  @[TLV::Field(tag: 5)]
  property message : String

  @[TLV::Field(tag: 6)]
  property encoded_message : Slice(UInt8)

  @[TLV::Field(tag: 7)]
  property array : Array(TLV::Value)

  @[TLV::Field(tag: 8)]
  property nested_packet : NestedPacket

  @[TLV::Field(tag: {0x235A, 42})]
  property foo : String

  @[TLV::Field(tag: {nil, 42})]
  property bar : String
end

class User
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property first_name : String

  @[TLV::Field(tag: 2)]
  property last_name : String
end

class NestedPacket
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  @[TLV::Field(tag: 2)]
  property message : String

  @[TLV::Field(tag: {nil, 1})]
  property array : Array(TLV::Value)

  @[TLV::Field(tag: {nil, 2})]
  property user : User
end

io = IO::Memory.new

writer = TLV::Writer.new(io)

input = {
             1 => 1,
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
packet = Packet.new(data)
pp packet

# Re-parse packet data into a new packet
packet2 = Packet.new(packet.to_slice)
pp packet2

is_equal = packet.to_slice == packet2.to_slice
puts "Is it equal? #{is_equal}"
```

## Contributing

1. Fork it (<https://github.com/spider-gazelle/tlv/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Giorgi Kavrelishvili](https://github.com/grkek) - creator and maintainer
