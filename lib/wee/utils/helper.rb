module Wee::Utils

  # [+component+]
  #   The component class for which to create an application object.  If a
  #   block is given, this will be invoked to create a new component object. 
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
  #   [:id_gen]
  #     The id generator to use for session-ids (default: Md5IdGenerator.new)
  # 
  def self.app_for(component=nil, options={}, &block)
    raise "either component or block must be given" if component.nil? and block.nil?  

    defaults = {
      :application => Wee::Application,
      :session => Wee::Session,
      :page_cache_capacity => 10,
      :id_gen => Wee::Md5IdGenerator.new
    }
    options = defaults.update(options)

    options[:application].new {|app|
      app.default_request_handler {
        options[:session].new {|sess|
          if component
            sess.root_component = component.new
          else
            sess.root_component = block.call
          end
          if sess.respond_to?(:page_store=)
            # This is so that you can use a Pageless session, which does not have
            # a page_store.
            sess.page_store = Wee::Utils::LRUCache.new(options[:page_cache_capacity])
          end
        }
      }
      app.id_generator = options[:id_gen]
    }
  end
end
