require 'test/unit'
require 'wee'

class Test_Component < Test::Unit::TestCase
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
  end

  def test_each_decoration
    require 'enumerator'
    c = Wee::Component.new
    d1 = Wee::Decoration.new
    d2 = Wee::Decoration.new
    d3 = Wee::Decoration.new

    c.add_decoration(d1)
    c.add_decoration(d2)
    c.add_decoration(d3)

    assert_equal [d3, d2, d1], c.to_enum(:each_decoration).to_a
  end

  def test_remove_decoration_if
    c = Wee::Component.new
    d1 = Wee::Decoration.new
    d2 = Wee::Decoration.new
    d3 = Wee::Decoration.new
    d4 = Wee::Decoration.new

    c.add_decoration(d1)
    c.add_decoration(d2)
    c.add_decoration(d3)
    c.add_decoration(d4)

    def d1.a() end
    def d3.a() end
    c.remove_decoration_if {|d| d.respond_to?(:a)}
    assert_equal [d4, d2], c.to_enum(:each_decoration).to_a

    def d4.a() end
    c.remove_decoration_if {|d| d.respond_to?(:a)}
    assert_equal [d2], c.to_enum(:each_decoration).to_a

    c.remove_decoration_if {|d| d.respond_to?(:a)}
    assert_equal [d2], c.to_enum(:each_decoration).to_a

    def d2.a() end
    c.remove_decoration_if {|d| d.respond_to?(:a)}
    assert_equal [], c.to_enum(:each_decoration).to_a

    assert_equal c, c.decoration
  end
end
