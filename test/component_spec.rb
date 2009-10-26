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
