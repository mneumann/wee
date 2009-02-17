module Wee

  #
  # Implementation of a Least Recently Used (LRU) Cache
  #
  class LRUCache
    class Item < Struct.new(:value, :time)
      def <=>(other)
        self.time <=> other.time
      end
    end

    def initialize(capacity=20, &replace_callback)
      @capacity = capacity
      @replace_callback = replace_callback
      @store = Hash.new
      @time = 0
    end

    def has_key?(key)
      @store.has_key?(key)
    end

    def delete(key)
      @store.delete(key)
    end

    def delete_if
      @store.delete_if {|id, item|
        yield id, item.value
      }
    end

    def fetch(key, default_value=nil)
      if item = @store[key]
        item.time = (@time += 1)
        item.value
      else
        default_value
      end
    end

    def store(key, value)
      if item = @store[key]
        # update item only
        item.time = (@time += 1)
        item.value = value
      else
        # insert new item
        item = Item.new
        item.time = (@time += 1)
        item.value = value
        garbage_collect() if @store.size >= @capacity
        while @store.size >= @capacity 
          old_item = @store.delete(min_key()) || raise
          @replace_callback.call(old_item) if @replace_callback
        end
        @store[key] = item
      end
    end

    def garbage_collect
    end

    def each(&block)
      @store.each(&block)
    end

    alias [] fetch
    alias []= store

    protected

    #
    # Returns the key of the minimum item
    #
    def min_key
      min_k, min_time = nil, @time
      @store.each {|k, v|
        if v.time < min_time 
          min_k, min_time = k, v.time
        end
      }
      return min_k
    end

  end # class LRUCache

end
