$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'
require 'window'

class Counter < Wee::Component
  def initialize(cnt)
    super()
    @cnt = cnt 
    session.register_object_for_backtracking(self)
  end

  def dec
    @cnt -= 1
  end

  def inc
    @cnt += 1
  end

  def render_content_on(r)
    r.anchor.action(:dec).with("--")
    r.space; r.text(@cnt.to_s); r.space 
    r.anchor.action(:inc).with("++")
  end
end

class MessageBox < Wee::Component
  def initialize(text)
    super()
    @text = text 
  end

  def render_content_on(r)
    r.break
    r.text(@text)
    r.form do 
      r.submit_button.value('OK').action(:answer, true)
      r.space
      r.submit_button.value('Cancel').action(:answer, false)
    end
    r.break
  end
end

class RegexpValidatedInput < Wee::Component

  def initialize(init_value, regexp)
    super()
    @regexp = regexp
    self.value = init_value
    @error = false
    session.register_object_for_backtracking(self)
  end

  def value
    @value
  end

  def value=(new_value)
    raise unless new_value =~ @regexp
    @input = @value = new_value
  end

  def render_content_on(r)
    r.form do
      r.text_input.attr(:input)
      r.text %(<div style="color: red">Invalid input</div>) if @error
    end
  end

  def input
    @input
  end

  def input=(str)
    @input = str

    if @input =~ @regexp
      @value = str 
      @error = false
    else
      @error = true
    end
  end

end

class EditableCounter < Counter 

  def initialize(cnt)
    super
    @show_edit_field = false
  end

  def render_content_on(r)
    #r.form.action(:submit).with do
      r.anchor.action(:dec).with("--")
      r.space

      if @show_edit_field
        r.text_input.assign(:cnt=).value(@cnt).size(6)
        r.submit_button.action(:submit).value('S')
      else
        r.anchor.action(:submit).with(@cnt) 
      end

      r.space
      r.anchor.action(:inc).with("++")
    #end
  end

  def submit
    if @cnt.to_s !~ /^\d+$/
      call MessageBox.new("You entered an invalid counter! Please try again!")
      @cnt = 0
    else
      @show_edit_field = !@show_edit_field
    end
    @cnt = @cnt.to_i
  end

  def cnt=(val)
    @cnt = val
  end

end

class MainPage < Wee::Component
  def initialize
    super()
    @counters = (1..10).map {|i| Wee::Window.new("Cnt #{ i }", "#{i*10}px", EditableCounter.new(i))}
    children.push(*@counters)
    children << (@val_inp = RegexpValidatedInput.new('Michael Neumann', /^\w+\s+\w+$/))

    @arr = []
    session.register_object_for_backtracking(@arr)
    session.register_object_for_backtracking(@text)
  end

  attr_accessor :text

  def render_content_on(r)
    r.page.title("Counter Test").with do 
      r.form do

      @counters.each { |cnt|
        r.render(cnt)  
      }

      r.render(@val_inp)

      @arr.each do |a|
        r.text(a)
        r.break
      end

      end

      r.form do
        r.text_input.assign(:text=)
        r.submit_button.action(:add).value('add')
      end

    end 
  end

  def add
    call MessageBox.new("Do you really want to add '" + @text + "'?"), :add_confirm
  end

  def add_confirm(res)
    call MessageBox.new("Do you really really really want to add '" + @text + "'?"), :add_confirm2 if res
  end

  def add_confirm2(res)
    @arr << @text if res
  end

end

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = MainPage.new
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
    end
  end
end

if __FILE__ == $0
  DUMP = 'dump'

  if File.exists?(DUMP)
    Wee::Application.load_from_disk(DUMP)
  else
    Wee::Application.new {|app|
      app.name = 'Counter'
      app.path = '/app'
      app.session_class = MySession
      app.session_store = Wee::Utils::LRUCache.new(1000) # handle up to 1000 sessions
      app.dumpfile = DUMP
    }
  end.start
end
