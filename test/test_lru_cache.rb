require 'test/unit'
require 'wee/lru_cache'

class I
  include Wee::LRUCache::Item

  attr_accessor :id

  def initialize(id)
    @id = id
  end
end

class Test_LRUCache < Test::Unit::TestCase
  def test_replacement
    cache = Wee::LRUCache.new(2)
    def cache.purge(item) @purged = item end
    def cache.purged() @purged end

    a = I.new("a")
    b = I.new("b")
    c = I.new("c")

    assert_nil cache.purged

    cache.store(a.id, a)
    assert_nil cache.purged

    cache.store(b.id, b)
    assert_nil cache.purged

    cache.store(c.id, c)
    assert_same a, cache.purged

    cache.store(a.id, a)
    assert_same b, cache.purged

    cache.store(b.id, b)
    assert_same c, cache.purged

    #
    # Reads also modify LRU
    #
    assert_same a, cache.fetch(a.id)
    assert_same b, cache.fetch(b.id)
    assert_same a, cache.fetch(a.id)

    cache.store(c.id, c)
    assert_same b, cache.purged
  end
end
