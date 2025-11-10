module TLV
  class Writer
    getter io : IO::Memory

    getter byte_format : IO::ByteFormat
    getter implicit_profile : Int32?

    getter stack : Array(UInt8) = [] of UInt8

    def initialize(@io : IO::Memory, @byte_format : IO::ByteFormat = IO::ByteFormat::LittleEndian, @implicit_profile : Int32? = nil)
    end

    def put(tag : Tag, value : Value)
      case value
      when .nil?
        put_null(tag)
      when .is_a?(Bool)
        put_bool(tag, value.as(Bool))
      when .is_a?(UInt8)
        put_unsigned_int(tag, value.as(UInt8))
      when .is_a?(UInt16)
        put_unsigned_int(tag, value.as(UInt16))
      when .is_a?(UInt32)
        put_unsigned_int(tag, value.as(UInt32))
      when .is_a?(UInt64)
        put_unsigned_int(tag, value.as(UInt64))
      when .is_a?(Int)
        put_signed_int(tag, value.as(Int))
      when .is_a?(Float32)
        put_float(tag, value.as(Float32))
      when .is_a?(Float64)
        put_double(tag, value.as(Float64))
      when .is_a?(String)
        put_string(tag, value.as(String))
      when .is_a?(Slice(UInt8))
        put_slice(tag, value.as(Slice(UInt8)))
      when .is_a?(Hash(Tag, Value))
        put_hash(tag, value.as(Hash(Tag, Value)))
      when .is_a?(Array(Value))
        put_array(tag, value.as(Array(Value)))
      when .is_a?(Enum)
        put(tag, value.value)
      end
    end

    def put_null(tag : Tag)
      # Write a TLV null with the specified TLV tag.
      encode_control_and_tag(type: Constants::Type::NULL, tag: tag)
    end

    def put_float(tag : Tag, value : Float32)
      # Write a value as a TLV float with the specified TLV tag.
      encode_control_and_tag(type: Constants::Type::FLOATING_POINT_NUMBER, tag: tag, value_length: 4)
      byte_format.encode(value, io)
    end

    def put_double(tag : Tag, value : Float64)
      # Write a value as a TLV float with the specified TLV tag.
      encode_control_and_tag(type: Constants::Type::FLOATING_POINT_NUMBER, tag: tag, value_length: 8)
      byte_format.encode(value, io)
    end

    def put_string(tag : Tag, value : String)
      # Write a value as a TLV string with the specified TLV tag.
      if value.bytesize < 0
        raise "Integer value out of range"
      end

      if value.bytesize <= Constants::IntegerSize::UINT8_MAX
        encode_control_and_tag(type: Constants::Type::UTF8_STRING, tag: tag, value_length: 1)
        byte_format.encode(UInt8.new(value.bytesize), io)

        io.write(value.to_slice)
      elsif value.bytesize <= Constants::IntegerSize::UINT16_MAX
        encode_control_and_tag(type: Constants::Type::UTF8_STRING, tag: tag, value_length: 2)
        byte_format.encode(UInt16.new(value.bytesize), io)

        io.write(value.to_slice)
      elsif value.bytesize <= Constants::IntegerSize::UINT32_MAX
        encode_control_and_tag(type: Constants::Type::UTF8_STRING, tag: tag, value_length: 4)
        byte_format.encode(UInt32.new(value.bytesize), io)

        io.write(value.to_slice)
      elsif value.bytesize <= Constants::IntegerSize::UINT64_MAX
        encode_control_and_tag(type: Constants::Type::UTF8_STRING, tag: tag, value_length: 8)
        byte_format.encode(UInt64.new(value.bytesize), io)

        io.write(value.to_slice)
      else
        raise "Integer value out of range"
      end
    end

    def put_slice(tag : Tag, value : Slice(UInt8))
      # Write a value as a TLV byte string with the specified TLV tag.
      if value.bytesize < 0
        raise "Integer value out of range"
      end

      if value.bytesize <= Constants::IntegerSize::UINT8_MAX
        encode_control_and_tag(type: Constants::Type::BYTE_STRING, tag: tag, value_length: 1)
        byte_format.encode(UInt8.new(value.bytesize), io)

        io.write(value)
      elsif value.bytesize <= Constants::IntegerSize::UINT16_MAX
        encode_control_and_tag(type: Constants::Type::BYTE_STRING, tag: tag, value_length: 2)
        byte_format.encode(UInt16.new(value.bytesize), io)

        io.write(value)
      elsif value.bytesize <= Constants::IntegerSize::UINT32_MAX
        encode_control_and_tag(type: Constants::Type::BYTE_STRING, tag: tag, value_length: 4)
        byte_format.encode(UInt32.new(value.bytesize), io)

        io.write(value)
      elsif value.bytesize <= Constants::IntegerSize::UINT64_MAX
        encode_control_and_tag(type: Constants::Type::BYTE_STRING, tag: tag, value_length: 8)
        byte_format.encode(UInt64.new(value.bytesize), io)

        io.write(value)
      else
        raise "Integer value out of range"
      end
    end

    def put_bool(tag : Tag, value : Bool)
      # Write a value as a TLV boolean with the specified TLV tag.
      encode_control_and_tag(type: Constants::Boolean::TRUE, tag: tag) if value
      encode_control_and_tag(type: Constants::Boolean::FALSE, tag: tag) unless value
    end

    def put_signed_int(tag : Tag, value : Int)
      # Write a value as a TLV signed integer with the specified TLV tag.
      if value >= Constants::IntegerSize::INT8_MIN && value <= Constants::IntegerSize::INT8_MAX
        encode_control_and_tag(type: Constants::Type::SIGNED_INTEGER, tag: tag, value_length: 1)
        byte_format.encode(Int8.new(value), io)
      elsif value >= Constants::IntegerSize::INT16_MIN && value <= Constants::IntegerSize::INT16_MAX
        encode_control_and_tag(type: Constants::Type::SIGNED_INTEGER, tag: tag, value_length: 2)
        byte_format.encode(Int16.new(value), io)
      elsif value >= Constants::IntegerSize::INT32_MIN && value <= Constants::IntegerSize::INT32_MAX
        encode_control_and_tag(type: Constants::Type::SIGNED_INTEGER, tag: tag, value_length: 4)
        byte_format.encode(Int32.new(value), io)
      elsif value >= Constants::IntegerSize::INT64_MIN && value <= Constants::IntegerSize::INT64_MAX
        encode_control_and_tag(type: Constants::Type::SIGNED_INTEGER, tag: tag, value_length: 8)
        byte_format.encode(Int64.new(value), io)
      else
        raise "Integer value out of range"
      end
    end

    def put_unsigned_int(tag : Tag, value : UInt8 | UInt16 | UInt32 | UInt64, force_size : Int32? = nil)
      # Write a value as a TLV unsigned integer with the specified TLV tag.
      # force_size: Optional size in bytes (1, 2, 4, or 8) to force specific encoding width.
      #             This is useful when the protocol requires a specific size regardless of value.
      if value < 0
        raise "Integer value out of range"
      end

      # Determine size to use (forced or automatic)
      size = if fs = force_size
               # Validate forced size
               unless [1, 2, 4, 8].includes?(fs)
                 raise "force_size must be 1, 2, 4, or 8 bytes"
               end
               # Ensure value fits in forced size
               case fs
               when 1
                 if value > Constants::IntegerSize::UINT8_MAX
                   raise "Value #{value} too large for forced size of 1 byte"
                 end
               when 2
                 if value > Constants::IntegerSize::UINT16_MAX
                   raise "Value #{value} too large for forced size of 2 bytes"
                 end
               when 4
                 if value > Constants::IntegerSize::UINT32_MAX
                   raise "Value #{value} too large for forced size of 4 bytes"
                 end
               end
               fs
             elsif value <= Constants::IntegerSize::UINT8_MAX
               1
             elsif value <= Constants::IntegerSize::UINT16_MAX
               2
             elsif value <= Constants::IntegerSize::UINT32_MAX
               4
             elsif value <= Constants::IntegerSize::UINT64_MAX
               8
             else
               raise "Integer value out of range"
             end

      # Encode with determined size
      case size
      when 1
        encode_control_and_tag(type: Constants::Type::UNSIGNED_INTEGER, tag: tag, value_length: 1)
        byte_format.encode(UInt8.new(value), io)
      when 2
        encode_control_and_tag(type: Constants::Type::UNSIGNED_INTEGER, tag: tag, value_length: 2)
        byte_format.encode(UInt16.new(value), io)
      when 4
        encode_control_and_tag(type: Constants::Type::UNSIGNED_INTEGER, tag: tag, value_length: 4)
        byte_format.encode(UInt32.new(value), io)
      when 8
        encode_control_and_tag(type: Constants::Type::UNSIGNED_INTEGER, tag: tag, value_length: 8)
        byte_format.encode(UInt64.new(value), io)
      end
    end

    def put_hash(tag : Tag, value_hash : Hash(Tag, Value))
      start_structure(tag: tag)

      structure = {} of BigInt => Tuple(Tag, Value)

      value_hash.keys.each do |key|
        structure.merge!({tag_to_sort_key(key) => {key, value_hash[key]}})
      end

      structure.keys.sort.each do |key|
        value = structure[key]
        put(value.first, value.last)
      end

      end_container()
    end

    def put_array(tag : Tag, values : Array(Value))
      start_array(tag)

      values.each do |value|
        self.put(nil, value)
      end

      end_container()
    end

    def start_container(tag : Tag, container_type : UInt8)
      # Start writing a TLV container with the specified TLV tag.
      verify_container_type(container_type)
      encode_control_and_tag(type: container_type, tag: tag)

      stack.insert(0, container_type)
    end

    def start_structure(tag : Tag)
      # Start writing a TLV structure with the specified TLV tag.
      start_container(tag: tag, container_type: Constants::Type::STRUCTURE)
    end

    def start_array(tag : Tag)
      # Start writing a TLV array with the specified TLV tag.
      start_container(tag: tag, container_type: Constants::Type::ARRAY)
    end

    def start_path(tag : Tag)
      # Start writing a TLV path with the specified TLV tag.
      start_container(tag: tag, container_type: Constants::Type::PATH)
    end

    def end_container
      # End writing the current TLV container.
      stack.delete_at(0, 1)
      encode_control_and_tag(type: Constants::Generic::END_OF_CONTAINER, tag: nil)
    end

    private def tag_to_sort_key(tag : Tag) : BigInt
      tag = tag.to_u8 if tag.is_a?(String)

      if tag.nil?
        return BigInt.new(-1)
      end

      if tag.is_a?(UInt8)
        major_order = BigInt.new(0)

        return (major_order << 32) + tag
      elsif tag.is_a?(Tuple(Int32?, Int32))
        profile_id, tag_number = tag.first, tag.last

        if profile_id.nil?
          major_order = BigInt.new(1)
          return (major_order << 32) + tag_number
        else
          major_order = BigInt.new(profile_id + 2)
          return (major_order << 32) + tag_number
        end
      else
        raise "Invalid TLV tag"
      end
    end

    private def verify_container_type(container_type : UInt8)
      if container_type != Constants::Type::STRUCTURE && container_type != Constants::Type::ARRAY && container_type != Constants::Type::PATH
        raise "Invalid TLV container type"
      end
    end

    private def encode_control_and_tag(type : UInt8, tag : Tag, value_length : UInt32 = 0)
      tag = tag.to_u8 if tag.is_a?(String)
      control_byte = type

      if value_length == 2
        control_byte |= 1
      elsif value_length == 4
        control_byte |= 2
      elsif value_length == 8
        control_byte |= 3
      end

      if tag.nil?
        if type != Constants::Generic::END_OF_CONTAINER && stack.size != 0 && stack.first == Constants::Type::STRUCTURE
          raise "Attempt to encode anonymous tag within TLV structure"
        end

        control_byte |= Constants::Control::ANONYMOUS

        byte_format.encode(control_byte.as(UInt8), io)
      end

      if tag.is_a?(UInt8)
        if tag < 0 || tag > Constants::IntegerSize::UINT8_MAX
          raise "Context-specific TLV tag number out of range"
        end

        if stack.size == 0
          raise "Attempt to encode context-specific TLV tag at top level"
        end

        if stack.first == Constants::Type::ARRAY
          raise "Attempt to encode context-specific tag within TLV array"
        end

        control_byte |= Constants::Control::CONTEXT_SPECIFIC

        byte_format.encode(control_byte.as(UInt8), io)
        byte_format.encode(tag.as(UInt8), io)
      end

      if tag.is_a?(Tuple(Int32?, Int32))
        profile, number = tag.first, tag.last

        unless number.is_a?(Int32)
          raise "Invalid object given for TLV tag"
        end

        if number < 0 || number > Constants::IntegerSize::UINT32_MAX
          raise "TLV tag number out of range"
        end

        unless profile.nil?
          unless profile.is_a?(Int32)
            raise "Invalid object given for TLV profile id"
          end

          if profile < 0 || profile > Constants::IntegerSize::UINT32_MAX
            raise "TLV profile id value out of range"
          end
        end

        if stack.size != 0 && stack.first == Constants::Type::ARRAY
          raise "Attempt to encode profile-specific tag within TLV array"
        end

        if profile.nil? || profile == implicit_profile
          if number <= Constants::IntegerSize::UINT16_MAX
            control_byte |= Constants::Control::IMPLICIT_PROFILE_TWO_BYTES

            byte_format.encode(control_byte.as(UInt8), io)
            byte_format.encode(UInt16.new(number), io)
          else
            control_byte |= Constants::Control::IMPLICIT_PROFILE_FOUR_BYTES

            byte_format.encode(control_byte.as(UInt8), io)
            byte_format.encode(UInt32.new(number), io)
          end
        elsif profile == 0
          if number <= Constants::IntegerSize::UINT16_MAX
            control_byte |= Constants::Control::COMMON_PROFILE_TWO_BYTES

            byte_format.encode(control_byte.as(UInt8), io)
            byte_format.encode(UInt16.new(number), io)
          else
            control_byte |= Constants::Control::COMMON_PROFILE_FOUR_BYTES

            byte_format.encode(control_byte.as(UInt8), io)
            byte_format.encode(UInt32.new(number), io)
          end
        else
          vendor_id = (profile >> 16) & 0xFFFF
          profile_number = (profile >> 0) & 0xFFFF

          if number <= Constants::IntegerSize::UINT16_MAX
            control_byte |= Constants::Control::FULLY_QUALIFIED_SIX_BYTES

            byte_format.encode(control_byte.as(UInt8), io)
            byte_format.encode(UInt16.new(vendor_id), io)
            byte_format.encode(UInt16.new(profile_number), io)
            byte_format.encode(UInt16.new(number), io)
          else
            control_byte |= Constants::Control::FULLY_QUALIFIED_EIGHT_BYTES

            byte_format.encode(control_byte.as(UInt8), io)
            byte_format.encode(UInt16.new(vendor_id), io)
            byte_format.encode(UInt16.new(profile_number), io)
            byte_format.encode(UInt16.new(profile), io)
            byte_format.encode(UInt16.new(number), io)
          end
        end
      end
    end
  end
end
