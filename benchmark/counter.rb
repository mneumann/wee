$LOAD_PATH.unshift '../lib'
require 'wee'
require 'wee/adaptors/webrick'
require 'wee/utils'

class Counter < Wee::Component 
  def initialize(cnt)
    super()
    @cnt = cnt 
    @show_edit_field = false
  end

  def backtrack_state(snap)
    super
    snap.add(self)
  end

  def dec
    @cnt -= 1
  end

  def inc
    @cnt += 1
  end

  def render
    r.form.callback(:submit).with do
      r.anchor.callback(:dec).with("--")
      r.space

      if @show_edit_field
        r.text_input.callback(:cnt=).value(@cnt).size(6)
      else
        r.anchor.callback(:submit).with(@cnt) 
      end

      r.space
      r.anchor.callback(:inc).with("++")
    end
  end

  def submit
    @show_edit_field = !@show_edit_field
  end

  def cnt
    @cnt
  end

  def cnt=(val)
    if val =~ /^\d+$/
      @cnt = val.to_i 
    end
  end
end

class Main < Wee::Component
  def initialize
    super()
    @counters = (1..COUNTERS).map {|i| Counter.new(i)}
    children.push(*@counters)
  end

  def render
    r.page.title("Counter Test").with do 
      @counters.each { |cnt| r.render(cnt) }
    end 
  end
end

if __FILE__ == $0
  PORT = (ARGV[0] || 2000).to_i
  COUNTERS = (ARGV[1] || 20).to_i
  File.open("counter.#{ PORT }.pid", 'w+') {|f| f.puts($$.to_s) }
  app = Wee::Utils.app_for(Main, :id_seed => 0, :page_cache_capacity => 10)
  Wee::WEBrickAdaptor.register('/counter' => app).start(:Port => PORT) 
end
