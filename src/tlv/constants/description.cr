module TLV
  module Constants
    module Description
      TYPE = {
        0x00 => "Signed Integer 1-byte value",
        0x01 => "Signed Integer 2-byte value",
        0x02 => "Signed Integer 4-byte value",
        0x03 => "Signed Integer 8-byte value",
        0x04 => "Unsigned Integer 1-byte value",
        0x05 => "Unsigned Integer 2-byte value",
        0x06 => "Unsigned Integer 4-byte value",
        0x07 => "Unsigned Integer 8-byte value",
        0x08 => "Boolean False",
        0x09 => "Boolean True",
        0x0A => "Floating Point 4-byte value",
        0x0B => "Floating Point 8-byte value",
        0x0C => "UTF-8 String 1-byte length",
        0x0D => "UTF-8 String 2-byte length",
        0x0E => "UTF-8 String 4-byte length",
        0x0F => "UTF-8 String 8-byte length",
        0x10 => "Byte String 1-byte length",
        0x11 => "Byte String 2-byte length",
        0x12 => "Byte String 4-byte length",
        0x13 => "Byte String 8-byte length",
        0x14 => "Null",
        0x15 => "Structure",
        0x16 => "Array",
        0x17 => "Path",
        0x18 => "End of Collection",
      }

      CONTROL = {
        0x00 => "Anonymous",
        0x20 => "Context 1-byte",
        0x40 => "Common Profile 2-byte",
        0x60 => "Common Profile 4-byte",
        0x80 => "Implicit Profile 2-byte",
        0xA0 => "Implicit Profile 4-byte",
        0xC0 => "Fully Qualified 6-byte",
        0xE0 => "Fully Qualified 8-byte",
      }
    end
  end
end
