$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'
require 'window'

class Counter < Wee::Component
  def initialize(cnt)
    super()
    @cnt = cnt 
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

  def render_content_on(r)
    r.anchor.callback { dec }.with("--")
    r.space; r.text(@cnt.to_s); r.space 
    r.anchor.callback { inc }.with("++")
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
      r.submit_button.value('OK').callback { answer true }
      r.space
      r.submit_button.value('Cancel').callback { answer false }
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
  end

  def backtrack_state(snap)
    super
    snap.add(self)
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
      r.text_input.value(@input).callback(&method(:input=))
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
    #r.form.callback{submit}.with do
      r.anchor.callback { dec }.with("--")
      r.space

      if @show_edit_field
        r.text_input.callback{|@cnt|}.value(@cnt).size(6)
        r.submit_button.callback{submit}.value('S')
      else
        r.anchor.callback{submit}.with(@cnt) 
      end

      r.space
      r.anchor.callback{inc}.with("++")
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
    @text = ""

    @list1 = (0..9).to_a
    @selected1 = []
    @list2 = []
    @selected2 = []
  end

  def backtrack_state(snap)
    super
    snap.add(@arr)
    snap.add(@text)

    snap.add(@list1)
    snap.add(@selected1)
    snap.add(@list2)
    snap.add(@selected2)
  end

  attr_accessor :text

  def render_content_on(r)
    r.page.title("Counter Test").with do 

      r.form do
        r.select_list(@list1).size(10).multiple.selected(@selected1).callback {|choosen| @selected1.replace(choosen)}
        r.submit_button.value('-&gt;').callback { @list2.push(*@selected1); @list1.replace(@list1-@selected1); @selected1.replace([]) } 
        r.submit_button.value('&lt;-').callback { @list1.push(*@selected2); @list2.replace(@list2-@selected2); @selected2.replace([]) } 
        r.select_list(@list2).size(10).multiple.selected(@selected2).callback {|choosen| @selected2.replace(choosen)}
      end

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
        r.text_input.value(@text).callback{|@text|}
        r.submit_button.callback{add}.value('add')
      end

    end 
  end

  def add
    if call(MessageBox.new("Do you really want to add '" + @text + "'?"))
      @arr << @text if call(MessageBox.new("Do you really really really want to add '" + @text + "'?"))
    end
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

#Wee::Application.register '/app', MySession 

#Wee::Application.new('/app', MySession


if __FILE__ == $0
  Wee::Application.new {|app|
    app.default_request_handler { MySession.new }
    app.id_generator = Wee::SimpleIdGenerator.new(rand(1_000_000))
  }.start(:mount_path => '/app')
end
