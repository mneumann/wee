require 'test/unit'
$LOAD_PATH.unshift "../lib"
module Wee; end
require 'wee/presenter'
require 'wee/component'
require 'wee/decoration'
require 'wee/holder'

# Mock
class Wee::Session
  def self.current
    @session ||= new
  end

  def register_object_for_backtracking(obj)
    #p obj 
  end
end

class TC_Component < Test::Unit::TestCase
  def test_add_remove_one_decoration
    c = Wee::Component.new
    d = Wee::Decoration.new

    assert_same c, c.decoration
    assert_nil d.owner

    c.add_decoration(d)

    assert_same d, c.decoration
    assert_same c, d.owner
    assert_same d, d.owner.decoration

    assert_same d, c.remove_decoration(d)

    assert_same c, c.decoration  
    assert_nil d.owner
  end

  def test_add_remove_multiple_decorations
    c = Wee::Component.new
    d1 = Wee::Decoration.new
    d2 = Wee::Decoration.new
    d3 = Wee::Decoration.new

    c.add_decoration(d1)
    c.add_decoration(d2)
    c.add_decoration(d3)

    assert_same d3, c.decoration 
    assert_same d2, d3.owner 
    assert_same d1, d2.owner
    assert_same c, d1.owner

    assert_same d2, c.remove_decoration(d2)

    assert_same d3, c.decoration 
    assert_same d1, d3.owner 
    assert_nil  d2.owner  
    assert_same c, d1.owner

    assert_same d1, c.remove_decoration(d1)
    assert_same d3, c.decoration
    assert_same c, d3.owner   
    assert_nil  d1.owner

    # try to remove an already removed decoration 
    assert_nil c.remove_decoration(d2)
    assert_nil c.remove_decoration(d1)  

    assert_same d3, c.remove_decoration(d3)
    assert_same c, c.decoration
    assert_nil  d3.owner

    # TODO: teste, wenn man zuerst die erste decoration löscht
    # TODO: Circular references and CC's
  end


end
