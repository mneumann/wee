$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'
require 'cgi'

require 'enumerator'

module ObjectSpaceBrowser

  class Klasses < Wee::Component

   def klasses
      ObjectSpace.to_enum(:each_object, Class).sort_by{|k| k.name}
    end

    def choose(klass)
      call(Klass.new(klass))
    end

    def render_content_on(r)
      r.h1 "Classes"

      r.ul {
        klasses.each do |klass|
          r.li { r.anchor.action(:choose, klass).with(klass.name) }
        end
      }
    end
  end

  class Klass < Wee::Component

    def initialize(klass)
      super()
      @klass = klass
      set_instances
    end

    def choose(instance)
      call Instance.new(instance)
    end

    ##
    # Fetches all instances of the klass sorted by object_id

    def set_instances
      @instances =
        case @klass
        when Symbol
          Symbol.all_symbols.sort_by do |s| s.to_s end
        else
          ObjectSpace.to_enum(:each_object, @klass).sort_by{|i| i.object_id}
        end
    end

    def render_content_on(r)
      instances = @instances
      r.h1 "Class #{@klass.name}"
      r.h2 "#{@instances.length} Instances"

      return if @instances.length.zero?

      r.ul {
        @instances.each do |instance|
          r.li { r.anchor.action(:choose, instance).with("0x%x" % instance.object_id) }
        end
      }
    end

  end

  class Instance < Wee::Component

    def initialize(instance)
      super()
      @instance = instance
      session.register_object_for_backtracking(@decoration)
    end

    def choose(instance)
      call Instance.new(instance)
    end

    def back
      answer
    end

    def render_content_on(r)
      r.anchor.action(:back).with("back")

      r.break
      r.h1 "Instance 0x%x of #{@instance.class.name}" % @instance.object_id

      case @instance
      when Array
        r.bold("array elements: ")
        r.break
        r.ul do
          @instance.each do |obj|
            r.li { render_obj(obj, r) }
          end
        end
      when Hash
        r.bold("hash elements: ")
        r.break
        r.table.border(1).with do
          r.table_row do
            r.table_data do r.bold("Key") end
            r.table_data do r.bold("Value") end
          end

          @instance.each_pair do |k, v|
            r.table_row do
              r.table_data { render_obj(k, r) }
              r.table_data { render_obj(v, r) }
            end
          end
        end

      when String, Float, Fixnum, Bignum, Numeric, Integer, Symbol
        r.encode_text(@instance.inspect)
      end
        
      return if @instance.instance_variables.empty?
      r.break

      render_instance_variables(r)
    end

    def render_instance_variables(r)
      r.table.border(1).with do
        r.table_row do
          r.table_data do r.bold("Instance Variable") end
          r.table_data do r.bold("Object") end
        end
        @instance.instance_variables.each do |var| render_ivar_row(var, r) end
      end
    end

    def render_ivar_row(var, r)
      r.table_row do 
        r.table_data(var)
        r.table_data do
          v = @instance.instance_variable_get(var)
          render_obj(v, r)
        end
      end
    end

    def render_obj(obj, r)
      r.anchor.action(:choose, obj).with do
        r.bold(obj.class.name)
        r.space
        r.text("(#{ obj.object_id })")
        r.space
        r.space

        case obj
        when String, Float, Integer, Symbol
          r.encode_text(obj.inspect)
        else
          r.encode_text(obj.inspect[0, 40] + "...")
        end
      end 
    end

  end

end # module ObjectSpaceBrowser

if $0 == __FILE__ then

OBJ = {
  "hello" => { [1,2,3] => [5,6,7], "test" => :super },
  "other" => %w(a b c d e f)
}

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = ObjectSpaceBrowser::Instance.new(OBJ)
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
    end
  end
end

class MyApplication < Wee::Application
  def shutdown
  end
end

  Wee::Application.new {|app|
    app.name = 'ObjectBrowser'
    app.path = '/ob'
    app.session_class = MySession
    app.session_store = Wee::Utils::LRUCache.new(10)
    app.dumpfile = ''
  }.start
end
