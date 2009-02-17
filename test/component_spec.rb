require 'wee/component'

describe Wee::Component, "when first created" do
  before do
    @component = Wee::Component.new
  end

  it "should have no children" do
    children = []
    @component.send(:each_child) {|c| children << c}
    children.should be_empty
  end

  it "should have no decoration" do
    @component.decoration.should == @component
  end
end
