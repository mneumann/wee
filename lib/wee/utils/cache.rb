require 'cache/cache'

module Wee::Utils; end

class Wee::Utils::LRUCache < Cache::StorageCache
  def initialize(capacity=20)
    super(Cache::Strategy::LRU.new(capacity))
  end
end
