module Wee::Utils

  # [+component+]
  #   The component class for which to create an application object.
  #
  # [+options+]
  #   A Hash. Following keys are accepted:
  # 
  #   [:application]
  #     The application class to use (default: Wee::Application)
  #
  #   [:session]
  #     The session class to use (default: Wee::Session)
  #
  #   [:page_cache_capacity]
  #     The size of the sessions page_store (default: 10)
  #
  #   [:id_seed]
  #     Initial value of the SimpleIdGenerator (default: rand(1_000_000)) 
  # 
  def self.app_for(component, options)
    defaults = {
      :application => Wee::Application,
      :session => Wee::Session,
      :page_cache_capacity => 10,
      :id_seed => rand(1_000_000)
    }
    options = defaults.update(options)

    options[:application].new {|app|
      app.default_request_handler {
        options[:session].new {|sess|
          sess.root_component = component.new
          sess.page_store = Wee::Utils::LRUCache.new(options[:page_cache_capacity])
        }
      }
      app.id_generator = Wee::SimpleIdGenerator.new(options[:id_seed])
    }
  end
end
