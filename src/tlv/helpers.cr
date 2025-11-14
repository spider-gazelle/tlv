# Helper methods to simplify TLV parsing
module TLV
  module Helpers
    # Safely get a value from a TLV hash by tag, trying multiple tag type variations
    def self.get_by_tag(hash : Hash(Tag, Value), tag : Int32) : Value?
      # Try UInt8 first (most common for context tags)
      return hash[tag.to_u8] if hash.has_key?(tag.to_u8)

      # Try Int32
      return hash[tag] if hash.has_key?(tag)

      # Try String
      tag_str = tag.to_s
      return hash[tag_str] if hash.has_key?(tag_str)

      # Try finding by value comparison
      hash.each do |k, v|
        if k.responds_to?(:to_i) && k.to_i == tag
          return v
        end
      end

      nil
    end

    # Extract from "Any" anonymous structure
    def self.unwrap_anonymous(hash : Hash(Tag, Value)) : Hash(Tag, Value)
      hash["Any"].as(Hash(Tag, Value))
    end

    # Get array field by tag
    def self.get_array(hash : Hash(Tag, Value), tag : Int32) : Array(Value)?
      value = get_by_tag(hash, tag)
      value.as?(Array)
    end

    # Get hash/structure field by tag
    def self.get_hash(hash : Hash(Tag, Value), tag : Int32) : Hash(Tag, Value)?
      value = get_by_tag(hash, tag)
      value.as?(Hash(Tag, Value))
    end

    # Get integer field by tag, handling different integer types
    def self.get_int(hash : Hash(Tag, Value), tag : Int32) : Int32?
      value = get_by_tag(hash, tag)
      return nil unless value

      case value
      when Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64
        value.to_i32
      else
        nil
      end
    end

    # Get UInt16 field by tag
    def self.get_uint16(hash : Hash(Tag, Value), tag : Int32) : UInt16?
      value = get_by_tag(hash, tag)
      return nil unless value

      case value
      when Int32, UInt16
        value.to_u16
      else
        nil
      end
    end

    # Get UInt32 field by tag
    def self.get_uint32(hash : Hash(Tag, Value), tag : Int32) : UInt32?
      value = get_by_tag(hash, tag)
      return nil unless value

      case value
      when Int32, UInt32
        value.to_u32
      else
        nil
      end
    end

    # Get boolean field by tag
    def self.get_bool(hash : Hash(Tag, Value), tag : Int32, default : Bool = false) : Bool
      value = get_by_tag(hash, tag)
      value.as?(Bool) || default
    end

    # Get bytes field by tag
    def self.get_bytes(hash : Hash(Tag, Value), tag : Int32) : Bytes?
      value = get_by_tag(hash, tag)
      value.as?(Bytes)
    end

    # Parse attribute path from either list-form or structure-form
    # List-form: [endpoint, cluster, attribute]
    # Structure-form: {2 => endpoint, 3 => cluster, 4 => attribute}
    def self.parse_attribute_path(value : Value) : {UInt16?, UInt32?, UInt32?}
      case value
      when Array
        # List-form: [endpoint, cluster, attribute, ...]
        ep_val = value[0]?.as?(Int32)
        endpoint = ep_val ? ep_val.to_u16 : nil

        cl_val = value[1]?.as?(Int32)
        cluster = cl_val ? cl_val.to_u32 : nil

        at_val = value[2]?.as?(Int32)
        attribute = at_val ? at_val.to_u32 : nil

        {endpoint, cluster, attribute}
      when Hash
        # Structure-form with tags
        hash = value.as(Hash(Tag, Value))
        endpoint = get_uint16(hash, 2)
        cluster = get_uint32(hash, 3)
        attribute = get_uint32(hash, 4)
        {endpoint, cluster, attribute}
      else
        {nil, nil, nil}
      end
    end
  end
end
