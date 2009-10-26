require 'wee/component'

describe Wee::Component, "when first created" do
  before do
    @component = Wee::Component.new
  end

  it "should have no children" do
    @component.children.should be_empty
  end

  it "should have no decoration" do
    @component.decoration.should == @component 
  end
end

describe Wee::Component, "after adding one decoration" do
  before do
    @component = Wee::Component.new
    @decoration = Wee::Decoration.new
    @component.add_decoration(@decoration)
  end

  it "should point to the added decoration" do
    @component.decoration.should == @decoration
  end

  it "the added decoration should point back to the component" do
    @component.decoration.next.should == @component
  end

  it "should return decoration after removing it" do
    @component.remove_decoration(@decoration).should == @decoration
  end

  it "should have no decoration after removing it" do
    @component.remove_decoration(@decoration)
    @component.decoration.should == @component 
  end
end
