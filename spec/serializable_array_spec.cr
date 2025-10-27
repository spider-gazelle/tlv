require "./spec_helper"

# Define test structs at module level
module SerializableArrayTest
  struct Item
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property id : UInt8

    @[TLV::Field(tag: 1)]
    property name : String

    def initialize(@id : UInt8, @name : String)
    end
  end

  struct Container
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property status : UInt8

    @[TLV::Field(tag: 1)]
    property items : Array(Item)?

    def initialize(@status : UInt8, @items : Array(Item)? = nil)
    end
  end

  struct NestedItem
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property value : UInt16

    def initialize(@value : UInt16)
    end
  end

  struct Parent
    include TLV::Serializable

    @[TLV::Field(tag: 0)]
    property children : Array(NestedItem)?

    def initialize(@children : Array(NestedItem)? = nil)
    end
  end
end

describe TLV::Serializable do
  describe "Array of Serializable types" do
    it "serializes and deserializes array of TLV::Serializable structs" do
      # Create a container with items
      items = [
        SerializableArrayTest::Item.new(1_u8, "First"),
        SerializableArrayTest::Item.new(2_u8, "Second"),
        SerializableArrayTest::Item.new(3_u8, "Third"),
      ]
      container = SerializableArrayTest::Container.new(0_u8, items)

      # Serialize to bytes
      bytes = container.to_slice

      # Deserialize from bytes
      parsed = SerializableArrayTest::Container.new(bytes)

      # Verify
      parsed.status.should eq(0_u8)
      parsed.items.should_not be_nil
      parsed.items.not_nil!.size.should eq(3)
      parsed.items.not_nil![0].id.should eq(1_u8)
      parsed.items.not_nil![0].name.should eq("First")
      parsed.items.not_nil![1].id.should eq(2_u8)
      parsed.items.not_nil![1].name.should eq("Second")
      parsed.items.not_nil![2].id.should eq(3_u8)
      parsed.items.not_nil![2].name.should eq("Third")
    end

    it "handles empty array of TLV::Serializable structs" do
      container = SerializableArrayTest::Container.new(0_u8, [] of SerializableArrayTest::Item)

      bytes = container.to_slice
      parsed = SerializableArrayTest::Container.new(bytes)

      parsed.status.should eq(0_u8)
      parsed.items.should_not be_nil
      parsed.items.not_nil!.size.should eq(0)
    end

    it "handles nil array of TLV::Serializable structs" do
      container = SerializableArrayTest::Container.new(0_u8, nil)

      bytes = container.to_slice
      parsed = SerializableArrayTest::Container.new(bytes)

      parsed.status.should eq(0_u8)
      parsed.items.should be_nil
    end

    it "manually encodes and parses array of structures" do
      # Manually build TLV structure
      io = IO::Memory.new
      writer = TLV::Writer.new(io)

      writer.start_structure(nil)
      writer.put(0_u8, 0_u8) # status

      # Array of items
      writer.start_array(1_u8)

      # First item
      writer.start_structure(nil)
      writer.put(0_u8, 1_u8)    # id
      writer.put(1_u8, "First") # name
      writer.end_container

      # Second item
      writer.start_structure(nil)
      writer.put(0_u8, 2_u8)     # id
      writer.put(1_u8, "Second") # name
      writer.end_container

      writer.end_container # End array
      writer.end_container # End structure

      bytes = io.rewind.to_slice

      # Parse it
      parsed = SerializableArrayTest::Container.new(bytes)

      parsed.status.should eq(0_u8)
      parsed.items.should_not be_nil
      parsed.items.not_nil!.size.should eq(2)
      parsed.items.not_nil![0].id.should eq(1_u8)
      parsed.items.not_nil![0].name.should eq("First")
      parsed.items.not_nil![1].id.should eq(2_u8)
      parsed.items.not_nil![1].name.should eq("Second")
    end

    it "works with nested serializable structs" do
      parent = SerializableArrayTest::Parent.new([
        SerializableArrayTest::NestedItem.new(100_u16),
        SerializableArrayTest::NestedItem.new(200_u16),
        SerializableArrayTest::NestedItem.new(300_u16),
      ])

      bytes = parent.to_slice
      parsed = SerializableArrayTest::Parent.new(bytes)

      parsed.children.should_not be_nil
      parsed.children.not_nil!.size.should eq(3)
      parsed.children.not_nil![0].value.should eq(100_u16)
      parsed.children.not_nil![1].value.should eq(200_u16)
      parsed.children.not_nil![2].value.should eq(300_u16)
    end
  end
end
