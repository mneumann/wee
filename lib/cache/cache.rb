unless Enumerable.instance_methods.include?("min_by")
  # for Ruby 1.8
  module Enumerable
    def min_by(&block)
      min {|i,j| block.call(i) <=> block.call(j) }
    end
  end
end

# Abstract super class of all cache implementations.
class Cache; end

# Abstract super class of all caching strategies.
class Cache::Strategy; end

# Implements an unbounded cache strategy. The cache size can grow to infinity.
class Cache::Strategy::Unbounded < Cache::Strategy
  class Item < Struct.new(:value); end
  def item_class() Item end

  def access(item) end
  def delete(item) end
  def insert_or_extrude(item, enum) end
end

# Abstract class for a capacity bounded strategy. Only up to _capacity_ items
# are allowed to be stored in the cache at any time.
class Cache::Strategy::CapacityBounded < Cache::Strategy
  attr_accessor :capacity

  def initialize(capacity)
    @capacity = capacity
    @n_items = 0  # number of items in cache
  end

  def inc(item)
    raise if full?
    @n_items += 1
  end

  def dec(item)
    raise if empty?
    @n_items -= 1
  end

  def full?
    @n_items >= @capacity 
  end

  def empty?
    @n_items == 0
  end
end

# Implements the least frequently used (LFU) strategy.
class Cache::Strategy::LFU < Cache::Strategy::CapacityBounded
  class Item < Struct.new(:value, :freq); end 
  def item_class() Item end

  def access(item)
    item.freq += 1
  end

  def delete(item)
    dec(item)
  end

  # enum::
  #    a [key, item] enumerable
  #
  def insert_or_extrude(item, enum)
    # find least recently used key/item and yield
    yield enum.min_by {|key, it| it.freq} while full?
    item.freq = 0 
    inc(item)
  end
end

# Implements the least recently used (LRU) strategy.
class Cache::Strategy::LRU < Cache::Strategy::CapacityBounded
  class Item < Struct.new(:value, :time); end 
  def item_class() Item end

  def access(item)
    item.time = Time.now
  end

  def delete(item)
    dec(item)
  end

  # enum::
  #    a [key, item] enumerable
  #
  def insert_or_extrude(item, enum)
    # find least recently used key/item and yield
    yield enum.min_by {|key, it| it.time} while full?
    item.time = Time.now
    inc(item)
  end
end

#
# Implements a cache using a parameterizable strategy and a storage. 
# The protocol that the _store_ must understand is: 
#
#   fetch(key) -> val
#   has_key?(key)
#   delete(key) -> val
#   each {|key, val| }
#
class Cache::StorageCache < Cache

  def initialize(strategy, store=Hash.new, store_on_update=false)
    @strategy = strategy
    @store = store
    @store_on_update = store_on_update
  end

  def has_key?(key)
    @store.has_key?(key)
  end

  def delete(key)
    if @store.has_key?(key)
      item = @store.delete(key)
      @strategy.delete(item)
      item.value
    else
      nil
    end
  end

  def fetch(key, default_value=nil)
    if @store.has_key?(key)
      item = @store.fetch(key)
      @strategy.access(item)
      @store.store(key, item) if @store_on_update
      item.value
    else
      default_value
    end
  end

  def store(key, value)
    if @store.has_key?(key)
      # update only 
      item = @store.fetch(key)
      item.value = value 
      @strategy.access(item)
      @store.store(key, item) if @store_on_update
    else 
      # insert new item
      item = @strategy.item_class.new 
      item.value = value  
      @strategy.insert_or_extrude(item, @store) do |k, i|
        @strategy.delete(i)
        @store.delete(k)
      end
      @store.store(key, item) # correct!
    end
    value
  end

  alias [] fetch
  alias []= store
end
