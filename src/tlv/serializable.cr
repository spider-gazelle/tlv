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
        {% index = 0 %}

        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(TLV::Field) %}
          {% unless ann && (ann[:ignore] || ann[:ignore_deserialize]) %}
            {% tag_value = (ann && ann[:tag]) || index %}
            {%
              properties[ivar.id] = {
                tag:         tag_value,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                type:        ivar.type,
                presence:    ann && ann[:presence],
              }
            %}
            {% index = index + 1 %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %var{name} = uninitialized ::Union(TLV::Value | {{value[:type]}})
          %found{name} = false
        {% end %}

        {% for name, value in properties %}
          if reader_object.keys.includes?("Any")
            root = reader_object["Any"].as(Hash(TLV::Tag, TLV::Value))

            # Try multiple key variations to handle type mismatches
            # Check string key (e.g., "1")
            if root.keys.includes?({{value[:tag]}}.to_s)
              %var{name} = root[{{value[:tag]}}.to_s]
              %found{name} = true
            end

            # Check Int32 key (from annotation)
            if !%found{name} && root.keys.includes?({{value[:tag]}})
              %var{name} = root[{{value[:tag]}}]
              %found{name} = true
            end

            # Check UInt8 key (TLV tag number) - only for simple integer tags
            {% if value[:tag].is_a?(NumberLiteral) %}
              if !%found{name} && root.keys.includes?({{value[:tag]}}.to_u8)
                %var{name} = root[{{value[:tag]}}.to_u8]
                %found{name} = true
              end
            {% end %}

            # Last resort: try all integer variants
            if !%found{name}
              root.each do |k, v|
                if k.responds_to?(:to_i) && k.to_i == {{value[:tag]}}
                  %var{name} = v
                  %found{name} = true
                  break
                end
              end
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

            # Handle TLV::Value and TLV::Value? (detected by large union size)
            # TLV::Value is a union of 16+ types, so if we see a field with that many union types,
            # it's likely TLV::Value or TLV::Value?, and we should just pass it through
            {% elsif value[:nilable] && value[:type].union_types.size > 10 %}
              # This is likely TLV::Value? - just pass through without casting
              @{{name}} = %var{name}
            {% elsif value[:type].union_types.size > 10 %}
              # This is likely TLV::Value - just pass through without casting
              @{{name}} = %var{name}.as(TLV::Value)

            {% elsif value[:nilable] && value[:type].union_types.includes?(Bool) %}
              # Handle Bool? (nilable Bool)
              if %var{name}.nil?
                @{{name}} = nil
              else
                @{{name}} = %var{name}.as(Bool)
              end

            # Handle nullable integer types
            {% elsif value[:nilable] && value[:type].union_types.includes?(Int8) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to Int8?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_i8
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(Int16) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to Int16?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_i16
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(Int32) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to Int32?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_i32
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(Int64) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to Int64?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_i64
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(UInt8) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to UInt8?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_u8
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(UInt16) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to UInt16?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_u16
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(UInt32) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to UInt32?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_u32
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(UInt64) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to UInt64?") unless %var{name}.responds_to?(:to_i)
                @{{name}} = %var{name}.to_u64
              end

            # Handle nullable float types
            {% elsif value[:nilable] && value[:type].union_types.includes?(Float32) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to Float32?") unless %var{name}.responds_to?(:to_f32)
                @{{name}} = %var{name}.to_f32
              end
            {% elsif value[:nilable] && value[:type].union_types.includes?(Float64) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to Float64?") unless %var{name}.responds_to?(:to_f)
                @{{name}} = %var{name}.to_f
              end

            # Handle nullable string type
            {% elsif value[:nilable] && value[:type].union_types.includes?(String) %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                raise Exception.new("Can not cast to String?") unless %var{name}.responds_to?(:to_s)
                @{{name}} = %var{name}.to_s
              end

            # Handle nullable Slice(UInt8)
            {% elsif value[:nilable] && value[:type].union_types.any? { |t| t == Slice(UInt8) } %}
              if %var{name}.nil?
                @{{name}} = nil
              else
                @{{name}} = %var{name}.as(Slice(UInt8))
              end

            {% elsif value[:type] == Slice(UInt8) %}
              @{{name}} = %var{name}.as(Slice(UInt8))
            {% elsif value[:type] == Hash(TLV::Tag, TLV::Value) %}
              @{{name}} = %var{name}.as(Hash(TLV::Tag, TLV::Value))
            {% elsif value[:type] == Array(TLV::Value) %}
              @{{name}} = %var{name}.as(Array(TLV::Value))
            {% else %}
              {% ancestors = value[:type].ancestors %}

              # Handle Array(SomeSerializableType) where SomeSerializableType includes TLV::Serializable
              {% type_name = value[:type].stringify %}
              {% if type_name.includes?("Array(") %}
                # It's an array type - extract element type
                {% if value[:type].nilable? %}
                  # Nilable array - find the non-nil type
                  {% actual_array_type = value[:type].union_types.find { |t| t != Nil } %}
                {% else %}
                  # Non-nilable array
                  {% actual_array_type = value[:type] %}
                {% end %}

                {% if actual_array_type %}
                  # Try to resolve the array type and get its type arguments
                  {% resolved_array = actual_array_type.resolve %}
                  {% if resolved_array && resolved_array.type_vars && resolved_array.type_vars.size > 0 %}
                    {% element_type = resolved_array.type_vars[0] %}
                    {% element_ancestors = element_type.ancestors %}

                    {% if element_ancestors.includes?(TLV::Serializable) %}
                      # Deserialize array of TLV::Serializable elements
                      array_value = %var{name}.as(Array(TLV::Value))
                      @{{name}} = array_value.map do |elem|
                        io = IO::Memory.new
                        writer = TLV::Writer.new(io)
                        writer.put(nil, elem)
                        {{element_type}}.new(io.rewind.to_slice)
                      end
                    {% end %}
                  {% end %}
                {% end %}
              {% end %}

              # Handle nullable enum types
              {% if value[:nilable] %}
                {% non_nil_type = value[:type].union_types.find { |t| t != Nil } %}
                {% if non_nil_type %}
                  {% non_nil_ancestors = non_nil_type.ancestors %}

                  {% if non_nil_ancestors.includes?(Enum) %}
                    # Nullable enum
                    if %var{name}.nil?
                      @{{name}} = nil
                    elsif %var{name}.responds_to?(:to_i)
                      @{{name}} = {{non_nil_type}}.from_value(%var{name}.to_i)
                    else
                      raise Exception.new("Unable to cast enum #{{{value[:tag]}}} from value #{%var{name}}")
                    end
                  {% elsif non_nil_ancestors.includes?(TLV::Serializable) %}
                    # Nullable TLV::Serializable
                    if %var{name}.nil?
                      @{{name}} = nil
                    else
                      io = IO::Memory.new
                      writer = TLV::Writer.new(io)
                      writer.put(nil, %var{name}.as(TLV::Value))
                      @{{name}} = {{non_nil_type}}.new(io.rewind.to_slice)
                    end
                  {% end %}
                {% end %}
              {% end %}

              # Handle non-nullable enum and serializable types
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
        {% index = 0 %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(TLV::Field) %}
          {% unless ann && (ann[:ignore] || ann[:ignore_serialize] == true) %}
            {% tag_value = (ann && ann[:tag]) || index %}
            {%
              properties[ivar.id] = {
                tag:              tag_value,
                type:             ivar.type,
                ignore_serialize: ann && ann[:ignore_serialize],
              }
            %}
            {% index = index + 1 %}
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

          # Handle nullable enum and TLV::Serializable types (but not arrays)
          {% type_name = value[:type].stringify %}
          {% if value[:type].nilable? && !type_name.includes?("Array(") %}
            {% non_nil_type = value[:type].union_types.find { |t| t != Nil } %}
            {% if non_nil_type %}
              {% non_nil_ancestors = non_nil_type.ancestors %}
              {% if non_nil_ancestors.includes?(TLV::Serializable) %}
                # Nullable TLV::Serializable
                if val = @{{name}}
                  input[tag] = val.to_h
                end
              {% elsif non_nil_ancestors.includes?(Enum) %}
                # Nullable Enum
                if val = @{{name}}
                  input[tag] = val.value
                end
              {% elsif non_nil_type == Bool %}
                # Nullable Bool - special case because false is falsy
                val = @{{name}}
                unless val.nil?
                  input[tag] = val
                end
              {% else %}
                # Other nullable primitive (already handled by basic if val = @{{name}})
                if val = @{{name}}
                  input[tag] = val
                end
              {% end %}
            {% end %}
          {% elsif ancestors.includes?(TLV::Serializable) %}
            input[tag] = @{{name}}.to_h
          {% elsif ancestors.includes?(Enum) %}
            input[tag] = @{{name}}.value
          {% else %}
            # Handle Array(SomeSerializableType) serialization
            {% type_name = value[:type].stringify %}
            {% if type_name.includes?("Array(") %}
              # It's an array type - extract element type
              {% if value[:type].nilable? %}
                # Nilable array - find the non-nil type
                {% actual_array_type = value[:type].union_types.find { |t| t != Nil } %}
              {% else %}
                #Non-nilable array
                {% actual_array_type = value[:type] %}
              {% end %}

              {% if actual_array_type %}
                # Try to resolve the array type and get its type arguments
                {% resolved_array = actual_array_type.resolve %}
                {% if resolved_array && resolved_array.type_vars && resolved_array.type_vars.size > 0 %}
                  {% element_type = resolved_array.type_vars[0] %}
                  {% element_ancestors = element_type.ancestors %}

                  {% if element_ancestors.includes?(TLV::Serializable) %}
                    # Serialize array of TLV::Serializable elements
                    if array = @{{name}}
                      input[tag] = array.map(&.to_h).map { |h| h.as(TLV::Value) }
                    end
                  {% else %}
                    # Regular array (not TLV::Serializable)
                    if val = @{{name}}
                      input[tag] = val
                    end
                  {% end %}
                {% end %}
              {% end %}
            {% else %}
              # Not an array at all
              if val = @{{name}}
                input[tag] = val
              end
            {% end %}
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
