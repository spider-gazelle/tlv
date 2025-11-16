module TLV
  class Reader
    getter io : IO::Memory = IO::Memory.new
    getter byte_format : IO::ByteFormat

    getter bytes_read : Int32 = 0

    getter decodings : Array(Value) = [] of Value

    def initialize(@data : Slice(UInt8), @byte_format : IO::ByteFormat = IO::ByteFormat::LittleEndian)
      io.write(data)
      io.rewind
    end

    def get
      # Get the dictionary representation of tlv data
      output = {} of Tag => Value
      decode_data(decodings, output)

      output
    end

    private def decode_control_byte(decoding : Hash(Tag, Value))
      byte = io.read_byte || raise "Unable to read from IO"

      control = Constants::Description::CONTROL[byte & 0xE0]
      type = Constants::Description::TYPE[byte & 0x1F]

      decoding["tagControl"] = control
      decoding["type"] = type
    end

    private def decode_control_and_tag(decoding : Hash(Tag, Value))
      # The control byte specifies the type of a TLV element and how its tag, length and value fields are encoded.
      # The control byte consists of two subfields: an element type field which occupies the lower 5 bits,
      # and a tag control field which occupies the upper 3 bits. The element type field encodes the element’s type
      # as well as how the corresponding length and value fields are encoded.  In the case of Booleans and the
      # null value, the element type field also encodes the value itself.

      decode_control_byte(decoding)

      if decoding["tagControl"] == "Anonymous"
        decoding["tag"] = nil
        decoding["tagLen"] = 0
      elsif decoding["tagControl"] == "Context 1-byte"
        decoding["tag"] = io.read_byte
        decoding["tagLen"] = 1
      elsif decoding["tagControl"] == "Common Profile 2-byte"
        profile = 0
        tag = io.read_bytes(UInt16, byte_format)

        decoding["profileTag"] = {Int32.new(profile), tag.to_i32}
        decoding["tagLen"] = 2
      elsif decoding["tagControl"] == "Common Profile 4-byte"
        profile = 0
        tag = io.read_bytes(UInt32, byte_format)

        decoding["profileTag"] = {Int32.new(profile), tag.to_i32}
        decoding["tagLen"] = 4
      elsif decoding["tagControl"] == "Implicit Profile 2-byte"
        profile = nil
        tag = io.read_bytes(UInt16, byte_format)

        decoding["profileTag"] = {profile, tag.to_i32}
        decoding["tagLen"] = 2
      elsif decoding["tagControl"] == "Implicit Profile 4-byte"
        profile = nil
        tag = io.read_bytes(UInt32, byte_format)

        decoding["profileTag"] = {profile, tag.to_i32}
        decoding["tagLen"] = 4
      elsif decoding["tagControl"] == "Fully Qualified 6-byte"
        vendor_id = io.read_bytes(UInt16, byte_format)
        profile_number = io.read_bytes(UInt16, byte_format)

        profile = (vendor_id << 16) | profile_number
        tag = io.read_bytes(UInt16, byte_format)

        decoding["profileTag"] = {Int32.new(profile), tag.to_i32}
        decoding["tagLen"] = 2
      elsif decoding["tagControl"] == "Fully Qualified 8-byte"
        vendor_id = io.read_bytes(UInt16, byte_format)
        profile_number = io.read_bytes(UInt16, byte_format)

        profile = (vendor_id << 16) | profile_number
        io.read_bytes(UInt16, byte_format)
        tag = io.read_bytes(UInt16, byte_format)

        decoding["profileTag"] = {Int32.new(profile), tag.to_i32}
        decoding["tagLen"] = 4
      end
    end

    private def decode_string_length(decoding : Hash(Tag, Value))
      # UTF-8 or Byte StringLength fields are encoded in 0, 1, 2 or 4 byte widths, as specified by
      # the element type field. If the element type needs a length field grab the next bytes as length

      if decoding["type"].to_s.includes?("length")
        if decoding["type"].to_s.includes?("1-byte")
          decoding["strDataLen"] = io.read_byte
          decoding["strDataLenLen"] = 1
        elsif decoding["type"].to_s.includes?("2-byte")
          decoding["strDataLen"] = io.read_bytes(UInt16, byte_format)
          decoding["strDataLenLen"] = 2
        elsif decoding["type"].to_s.includes?("4-byte")
          decoding["strDataLen"] = io.read_bytes(UInt32, byte_format)
          decoding["strDataLenLen"] = 4
        elsif decoding["type"].to_s.includes?("8-byte")
          decoding["strDataLen"] = io.read_bytes(UInt64, byte_format)
          decoding["strDataLenLen"] = 8
        end
      else
        decoding["strDataLen"] = 0_u8
        decoding["strDataLenLen"] = 0
      end
    end

    private def decode_values(decoding : Hash(Tag, Value))
      # decode primitive tlv value to the corresponding crystal value, tlv array and path are decoded as
      # array, tlv structure is decoded as hash
      if decoding["type"] == "Structure"
        decoding["value"] = {} of Tag => Value
        decoding["Structure"] = [] of Value

        decode_data(decoding["Structure"].as(Array(Value)), decoding["value"].as(Hash(Tag, Value)))
      elsif decoding["type"] == "Array"
        decoding["value"] = [] of Value
        decoding["Array"] = [] of Value

        decode_data(decoding["Array"].as(Array(Value)), decoding["value"].as(Array(Value)))
      elsif decoding["type"] == "Path"
        path_elements = [] of Value
        decoding["Path"] = [] of Value
        decoding["value"] = PathContainer.new(path_elements)

        decode_data(decoding["Path"].as(Array(Value)), path_elements)
      elsif decoding["type"] == "Null"
        decoding["value"] = nil
      elsif decoding["type"] == "End of Collection"
        decoding["value"] = nil
      elsif decoding["type"] == "Boolean True"
        decoding["value"] = true
      elsif decoding["type"] == "Boolean False"
        decoding["value"] = false
      elsif decoding["type"] == "Unsigned Integer 1-byte value"
        decoding["value"] = io.read_bytes(UInt8, byte_format)
      elsif decoding["type"] == "Signed Integer 1-byte value"
        decoding["value"] = io.read_bytes(Int8, byte_format)
      elsif decoding["type"] == "Unsigned Integer 2-byte value"
        decoding["value"] = io.read_bytes(UInt16, byte_format)
      elsif decoding["type"] == "Signed Integer 2-byte value"
        decoding["value"] = io.read_bytes(Int16, byte_format)
      elsif decoding["type"] == "Unsigned Integer 4-byte value"
        decoding["value"] = io.read_bytes(UInt32, byte_format)
      elsif decoding["type"] == "Signed Integer 4-byte value"
        decoding["value"] = io.read_bytes(Int32, byte_format)
      elsif decoding["type"] == "Unsigned Integer 8-byte value"
        decoding["value"] = io.read_bytes(UInt64, byte_format)
      elsif decoding["type"] == "Signed Integer 8-byte value"
        decoding["value"] = io.read_bytes(Int64, byte_format)
      elsif decoding["type"] == "Floating Point 4-byte value"
        decoding["value"] = io.read_bytes(Float32, byte_format)
      elsif decoding["type"] == "Floating Point 8-byte value"
        decoding["value"] = io.read_bytes(Float64, byte_format)
      elsif decoding["type"].to_s.includes?("UTF-8 String")
        begin
          length = extract_unsigned_integer(decoding["strDataLen"])
          buffer = Slice(UInt8).new(length)
          bytes_read = io.read_utf8(buffer)

          decoding["value"] = String.new(buffer)
        rescue exception
          length = extract_unsigned_integer(decoding["strDataLen"])
          decoding["value"] = io.read_string(length)
        end
      elsif decoding["type"].to_s.includes?("Byte String")
        length = extract_unsigned_integer(decoding["strDataLen"])
        buffer = Slice(UInt8).new(length)
        bytes_read = io.read(buffer)

        decoding["value"] = buffer
      else
        raise "Attempt to decode unsupported TLV type"
      end
    end

    private def extract_unsigned_integer(value)
      case value
      when .is_a?(UInt8)
        return value.as(UInt8)
      when .is_a?(UInt16)
        return value.as(UInt16)
      when .is_a?(UInt32)
        return value.as(UInt32)
      when .is_a?(UInt64)
        return value.as(UInt64)
      else
        raise "Invalid string data length"
      end
    end

    private def incomplete? : Bool
      io.bytesize != io.pos
    end

    private def decode_data(decodings : Array(Value), output : Hash(Tag, Value) | Array(Value))
      decoding = {} of Tag => Value

      while incomplete?
        decode_control_and_tag(decoding)
        decode_string_length(decoding)
        decode_values(decoding)

        decodings.push(decoding)

        if decoding["type"].to_s == "End of Collection"
          break
        else
          if decoding.keys.includes?("profileTag")
            profile_tag = decoding["profileTag"].as(Tuple(Int32?, Int32))

            if output.is_a?(Hash(Tag, Value))
              output[profile_tag] = decoding["value"]
            end
          elsif decoding.keys.includes?("tag")
            if output.is_a?(Hash(Tag, Value))
              tag = decoding["tag"] ? decoding["tag"].as(Tag) : "Any"
              output[tag] = decoding["value"]
            else
              output.push(decoding["value"])
            end
          else
            raise "Attempt to decode unsupported TLV tag"
          end
        end
      end

      decodings
    end
  end
end
