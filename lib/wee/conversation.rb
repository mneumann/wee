require 'wee/component'

module Wee

  class BlockComponent < Component
    def initialize(&block)
      @block = block
    end

    def render(r)
      instance_exec(r, &@block)
    end
  end

  class Component
    def display(&block)
      callcc BlockComponent.new(&block) 
    end

    def confirm(question)
      display do |r|
        r.h3 question
        r.submit_button.callback { answer true }.value("Yes"); r.space
        r.submit_button.callback { answer false }.value("No")
      end
    end

    def inform(message)
      display do |r|
        r.h3 message  
        r.submit_button.callback { answer }.value("Ok")
      end
    end

    def choose_from(items, caption=nil)
      display do |r|
        r.h3 caption if caption
        selection = nil
        r.select_list(items).callback {|s| selection = s }
        r.break
        r.submit_button.callback { answer selection }.value("Ok"); r.space
        r.submit_button.callback { answer nil }.value("Cancel")
      end
    end

  end

end
