module TLV
  annotation Field
  end

  module Serializable
    macro included
      # Define a `new` directly in the included type,
      # so it overloads well with other possible initializes

      def self.new(data : Slice(UInt8))
        new_from_tlv_data_parser(data)
      end

      private def self.new_from_tlv_data_parser(data : Slice(UInt8))
        instance = allocate
        instance.initialize(__data_for_tlv_serializable: data)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      # When the type is inherited, carry over the `new`
      # so it can compete with other possible initializes

      macro inherited
        def self.new(data : Slice(UInt8))
          new_from_tlv_data_parser(data)
        end
      end
    end

    def initialize(*, __data_for_tlv_serializable data : Slice(UInt8))
      reader = Reader.new(data)
      reader_object = reader.get

      {% begin %}
        {% properties = {} of Nil => Nil %}

        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(TLV::Field) %}
          {% unless ann && (ann[:ignore] || ann[:ignore_deserialize]) %}
            {%
              properties[ivar.id] = {
                tag:         ((ann && ann[:tag]) || @types.instance_vars.index(ivar)),
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                type:        ivar.type,
                presence:    ann && ann[:presence],
              }
            %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %var{name} = uninitialized ::Union(TLV::Value | {{value[:type]}})
          %found{name} = false
        {% end %}

        {% for name, value in properties %}
          if reader_object.keys.includes?("Any")
            root = reader_object["Any"].as(Hash(TLV::Tag, TLV::Value))

            # Check both String and Tuple based keys
            if root.keys.includes?({{value[:tag]}}.to_s)
              %var{name} = root[{{value[:tag]}}.to_s]
              %found{name} = true
            end

            if root.keys.includes?({{value[:tag]}})
              %var{name} = root[{{value[:tag]}}]
              %found{name} = true
            end
          end
        {% end %}

        {% for name, value in properties %}
          if %found{name}
            {% if value[:type] == Int8 %}
              raise Exception.new("Can not cast {{value[:type]}} to Int8") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_i8)
            {% elsif value[:type] == Int16 %}
              raise Exception.new("Can not cast {{value[:type]}} to Int16") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_i16)
            {% elsif value[:type] == Int32 %}
              raise Exception.new("Can not cast {{value[:type]}} to Int32") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_i32)
            {% elsif value[:type] == Int64 %}
              raise Exception.new("Can not cast {{value[:type]}} to Int64") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_i64)
            {% elsif value[:type] == UInt8 %}
              raise Exception.new("Can not cast {{value[:type]}} to UInt8") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_u8)
            {% elsif value[:type] == UInt16 %}
              raise Exception.new("Can not cast {{value[:type]}} to UInt16") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_u16)
            {% elsif value[:type] == UInt32 %}
              raise Exception.new("Can not cast {{value[:type]}} to UInt32") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_u32)
            {% elsif value[:type] == UInt64 %}
              raise Exception.new("Can not cast {{value[:type]}} to UInt64") unless %var{name}.responds_to?(:to_i)
              @{{name}} = {{value[:type]}}.new(%var{name}.to_u64)
            {% elsif value[:type] == String %}
              raise Exception.new("Can not cast {{value[:type]}} to String") unless %var{name}.responds_to?(:to_s)
              @{{name}} = %var{name}.to_s
            {% elsif value[:type] == Float32 %}
              raise Exception.new("Can not cast {{value[:type]}} to Float32") unless %var{name}.responds_to?(:to_f32)
              @{{name}} = %var{name}.to_f32
            {% elsif value[:type] == Float64 %}
              raise Exception.new("Can not cast {{value[:type]}} to Float64") unless %var{name}.responds_to?(:to_f)
              @{{name}} = %var{name}.to_f
            {% elsif value[:type] == Bool %}
              @{{name}} = %var{name}.as(Bool)
            {% elsif value[:type] == Slice(UInt8) %}
              @{{name}} = %var{name}.as(Slice(UInt8))
            {% elsif value[:type] == Hash(TLV::Tag, TLV::Value) %}
              @{{name}} = %var{name}.as(Hash(TLV::Tag, TLV::Value))
            {% elsif value[:type] == Array(TLV::Value) %}
              @{{name}} = %var{name}.as(Array(TLV::Value))
            {% else %}
              {% ancestors = value[:type].ancestors %}

              {% if ancestors.includes?(Enum) %}
                if %var{name}.responds_to?(:to_i)
                  @{{name}} = {{value[:type]}}.from_value(%var{name}.to_i)
                else
                  raise Exception.new("Unable to cast enum #{{{value[:tag]}}} from value #{%var{name}}")
                end
              {% end %}

              {% if ancestors.includes?(TLV::Serializable) %}
                io = IO::Memory.new
                writer = TLV::Writer.new(io)

                writer.put(nil, %var{name}.as(TLV::Value))

                @{{name}} = {{value[:type]}}.new(io.rewind.to_slice)
              {% end %}
            {% end %}
          else
            {% unless value[:has_default] || value[:nilable] %}
              raise Exception.new("Missing TLV attribute: {{value[:tag]}}")
            {% end %}
          end

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}
      {% end %}
    end

    def to_h : Hash(TLV::Tag, TLV::Value)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(TLV::Field) %}
          {% unless ann && (ann[:ignore] || ann[:ignore_serialize] == true) %}
            {%
              properties[ivar.id] = {
                tag:              ((ann && ann[:tag]) || @types.instance_vars.index(ivar)),
                type:             ivar.type,
                ignore_serialize: ann && ann[:ignore_serialize],
              }
            %}
          {% end %}
        {% end %}

        input = {} of TLV::Tag => TLV::Value

        {% for name, value in properties %}
          {% ancestors = value[:type].ancestors %}

          {% if value[:tag].is_a?(NumberLiteral) %}
            tag = {{value[:tag]}}.to_u8
          {% else %}
            tag = {{value[:tag]}}
          {% end %}

          {% if ancestors.includes?(TLV::Serializable) %}
            input[tag] = @{{name}}.to_h
          {% elsif ancestors.includes?(Enum) %}
            input[tag] = @{{name}}.value
          {% else %}
            input[tag] = @{{name}}
          {% end %}
        {% end %}

        input
      {% end %}
    end

    def to_slice(tag : Tag = nil) : Slice(UInt8)
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.put(tag, self.to_h)
      io.rewind.to_slice
    end
  end
end
