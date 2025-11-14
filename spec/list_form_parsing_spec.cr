require "./spec_helper"

# Test list-form support in TLV::Serializable
@[TLV::ListForm]
struct TestListFormPath
  include TLV::Serializable

  @[TLV::Field(tag: 2)]
  property endpoint : UInt16?

  @[TLV::Field(tag: 3)]
  property cluster : UInt32?

  @[TLV::Field(tag: 4)]
  property attribute : UInt32?

  def initialize(@endpoint = nil, @cluster = nil, @attribute = nil)
  end
end

describe "TLV ListForm Annotation" do
  it "parses list-form encoding [0, 29, 3]" do
    # Encode as list-form: [0, 29, 3]
    io = IO::Memory.new
    writer = TLV::Writer.new(io)

    writer.start_array(nil)
    writer.put(nil, 0)
    writer.put(nil, 29)
    writer.put(nil, 3)
    writer.end_container

    bytes = io.rewind.to_slice

    # Should automatically detect and parse list-form
    path = TestListFormPath.new(bytes)

    path.endpoint.should eq(0)
    path.cluster.should eq(29)
    path.attribute.should eq(3)
  end

  it "still parses structure-form {2=>0, 3=>29, 4=>3}" do
    # Encode as structure-form: {2 => 0, 3 => 29, 4 => 3}
    io = IO::Memory.new
    writer = TLV::Writer.new(io)

    writer.start_structure(nil)
    writer.put(2_u8, 0_u16)
    writer.put(3_u8, 29_u32)
    writer.put(4_u8, 3_u32)
    writer.end_container

    bytes = io.rewind.to_slice

    # Should still work with structure-form
    path = TestListFormPath.new(bytes)

    path.endpoint.should eq(0)
    path.cluster.should eq(29)
    path.attribute.should eq(3)
  end

  it "handles partial list-form [0, 29]" do
    # Encode as partial list: [0, 29] (attribute missing)
    io = IO::Memory.new
    writer = TLV::Writer.new(io)

    writer.start_array(nil)
    writer.put(nil, 0)
    writer.put(nil, 29)
    writer.end_container

    bytes = io.rewind.to_slice

    path = TestListFormPath.new(bytes)

    path.endpoint.should eq(0)
    path.cluster.should eq(29)
    path.attribute.should be_nil
  end
end
