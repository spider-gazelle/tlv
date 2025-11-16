module TLV
  # PathContainer is a wrapper around an array that preserves the PATH container type
  # during encode/decode cycles. This is necessary because PATH (0x17) and ARRAY (0x16)
  # containers have different semantics in the Matter protocol, but both decode to arrays.
  class PathContainer
    getter elements : Array(Value)

    def initialize(@elements : Array(Value) = [] of Value)
    end

    def <<(value : Value)
      @elements << value
    end

    def push(value : Value)
      @elements.push(value)
    end

    def [](index : Int)
      @elements[index]
    end

    def []=(index : Int, value : Value)
      @elements[index] = value
    end

    def size
      @elements.size
    end

    def empty?
      @elements.empty?
    end

    def each(&)
      @elements.each do |element|
        yield element
      end
    end

    def map(&block)
      @elements.map(&block)
    end

    def to_a
      @elements
    end

    def ==(other : PathContainer)
      @elements == other.elements
    end

    def ==(other : Array(Value))
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
