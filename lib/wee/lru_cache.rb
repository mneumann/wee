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
        while @store.size >= @capacity 
          min_k, min_time = nil, @time
          @store.each {|k, v|
            if v.time < min_time 
              min_k, min_time = k, v.time
            end
          }
          old_item = @store.delete(min_k) || raise
          @replace_callback.call(old_item) if @replace_callback
        end
        @store[key] = item
      end
    end

    def each(&block)
      @store.each(&block)
    end

    alias [] fetch
    alias []= store

  end # class LRUCache

end
