module Wee

  #
  # Implementation of a Least Recently Used (LRU) Cache
  #
  class LRUCache

    #
    # Common interface for all items
    #
    module Item
      attr_accessor :lru_time
    end

    def initialize(capacity=20)
      @capacity = capacity
      @store = Hash.new
      @time = 0
    end

    def has_key?(key)
      @store.has_key?(key)
    end

    def delete(key)
      @store.delete(key)
    end

    def delete_if(&block)
      @store.delete_if(&block)
    end

    def fetch(key, default_value=nil)
      if item = @store[key]
        touch(item)
        item
      else
        default_value
      end
    end

    def store(key, item)
      touch(item)
      compact()
      @store[key] = item
    end

    protected

    #
    # Is called whenever an item is looked up or stored to update it's
    # timestamp to maintain least recently used information.
    #
    def touch(item)
      item.lru_time = (@time += 1)
    end

    #
    # Is called for each item that is replaced from cache. Overwrite.
    #
    def purge(item)
    end

    #
    # Is called before replacing old items in order to remove items
    # known-to-be no longer in use. Overwrite.
    #
    def garbage_collect
    end

    #
    # Replaces old items and makes place for new.
    #
    def compact
      garbage_collect() if @store.size >= @capacity
      while @store.size >= @capacity
        purge(@store.delete(min_key()) || raise)
      end
    end

    #
    # Returns the key of the minimum item
    #
    def min_key
      min_k, _ = @store.min_by {|_, item| item.lru_time}
      return min_k
    end

  end # class LRUCache

end
