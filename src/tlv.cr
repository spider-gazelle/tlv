require "big"
require "json"
require "./tlv/**"

module TLV
  alias Tag = Nil | UInt8 | String | Tuple(Int32?, Int32)
  alias Value = Nil | UInt8 | UInt16 | UInt32 | UInt64 | Int8 | Int16 | Int32 | Int64 | Bool | Float32 | Float64 | String | Slice(UInt8) | Hash(Tag, Value) | Array(Value) | Tuple(Int32?, Int32)
end
