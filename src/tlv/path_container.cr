module TLV
  # PathContainer is a wrapper around a hash that preserves the PATH container type
  # during encode/decode cycles. This is necessary because PATH (0x17) and STRUCTURE (0x15)
  # containers have different semantics in the Matter protocol, but both decode to hashes.
  # PATH containers contain tagged elements (endpoint, cluster, attribute) like structures.
  class PathContainer
    getter elements : Hash(Tag, Value)

    def initialize(@elements : Hash(Tag, Value) = {} of Tag => Value)
    end

    def []=(key : Tag, value : Value)
      @elements[key] = value
    end

    def [](key : Tag)
      @elements[key]
    end

    def []?(key : Tag)
      @elements[key]?
    end

    def has_key?(key : Tag)
      @elements.has_key?(key)
    end

    def keys
      @elements.keys
    end

    def values
      @elements.values
    end

    def size
      @elements.size
    end

    def empty?
      @elements.empty?
    end

    def each(&)
      @elements.each do |key, value|
        yield key, value
      end
    end

    def map(&block)
      @elements.map(&block)
    end

    def to_h
      @elements
    end

    def ==(other : PathContainer)
      @elements == other.elements
    end

    def ==(other : Hash(Tag, Value))
      @elements == other
    end

    def inspect(io : IO)
      io << "PathContainer("
      @elements.inspect(io)
      io << ")"
    end

    def to_s(io : IO)
      inspect(io)
    end
  end
end
