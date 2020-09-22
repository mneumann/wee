require 'wee/component'

describe Wee::Component, "when first created" do
  before do
    @component = Wee::Component.new
  end

  it "should have no children" do
    expect(@component.children).to be_empty
  end

  it "should have no decoration" do
    expect(@component.decoration).to eq(@component)
  end
end

describe Wee::Component, "after adding one decoration" do
  before do
    @component = Wee::Component.new
    @decoration = Wee::Decoration.new
    @component.add_decoration(@decoration)
  end

  it "should point to the added decoration" do
    expect(@component.decoration).to eq(@decoration)
  end

  it "the added decoration should point back to the component" do
    expect(@component.decoration.next).to eq(@component)
  end

  it "should return decoration after removing it" do
    expect(@component.remove_decoration(@decoration)).to eq(@decoration)
  end

  it "should have no decoration after removing it" do
    @component.remove_decoration(@decoration)
    expect(@component.decoration).to eq(@component)
  end
end
