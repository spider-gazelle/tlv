module TLV
  module Constants
    module Type
      SIGNED_INTEGER        = 0x00_u8
      UNSIGNED_INTEGER      = 0x04_u8
      BOOLEAN               = 0x08_u8
      FLOATING_POINT_NUMBER = 0x0A_u8
      UTF8_STRING           = 0x0C_u8
      BYTE_STRING           = 0x10_u8
      NULL                  = 0x14_u8
      STRUCTURE             = 0x15_u8
      ARRAY                 = 0x16_u8
      PATH                  = 0x17_u8
    end
  end
end
