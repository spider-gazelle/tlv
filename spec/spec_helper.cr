require "spec"
require "../src/tlv"

enum Id : UInt8
  A
  B
  C
  D
end

class Packet
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : Id

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
