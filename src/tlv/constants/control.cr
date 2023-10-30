module TLV
  module Constants
    module Control
      ANONYMOUS                   = 0x00
      CONTEXT_SPECIFIC            = 0x20
      COMMON_PROFILE_TWO_BYTES    = 0x40
      COMMON_PROFILE_FOUR_BYTES   = 0x60
      IMPLICIT_PROFILE_TWO_BYTES  = 0x80
      IMPLICIT_PROFILE_FOUR_BYTES = 0xA0
      FULLY_QUALIFIED_SIX_BYTES   = 0xC0
      FULLY_QUALIFIED_EIGHT_BYTES = 0xE0
    end
  end
end
