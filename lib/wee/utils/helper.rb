require 'wee/utils/cache'

module Wee::Helper
  def self.app_for(component, page_cache_capacity=10, id_seed=rand(1_000_000))
    Wee::Application.new {|app|
      app.default_request_handler {
        Wee::Session.new {|sess|
          sess.root_component = component.new
          sess.page_store = Wee::Utils::LRUCache.new(page_cache_capacity)
        }
      }
      app.id_generator = Wee::SimpleIdGenerator.new(id_seed)
    }
  end
end
