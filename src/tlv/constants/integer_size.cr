module TLV
  module Constants
    module IntegerSize
      INT8_MIN  =                  -128_i8
      INT16_MIN =               -32768_i16
      INT32_MIN =          -2147483648_i32
      INT64_MIN = -9223372036854775808_i64

      INT8_MAX  =                  127_i8
      INT16_MAX =               32767_i16
      INT32_MAX =          2147483647_i32
      INT64_MAX = 9223372036854775807_i64

      UINT8_MAX  =                   255_u8
      UINT16_MAX =                65535_u16
      UINT32_MAX =           4294967295_u32
      UINT64_MAX = 18446744073709551615_u64
    end
  end
end
