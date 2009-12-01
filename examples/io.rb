module Wee

  class BlockComponent < Component
    def initialize(&block)
      @block = block
    end

    def render(r)
      instance_exec(r, &@block)
    end
  end

  class IO
    def initialize(component)
      @component = component
    end

    def ask
      render do |r|
        r.text_input.callback {|text| answer(text)}
        r.submit_button.value("Enter")
      end 
    end

    def pause(text)
      render {|r| r.anchor.callback { answer }.with(text) }
    end

    def tell(text)
      render {|r| r.text text.to_s; r.break }
    end

    protected

    def render(&block)
      @component.callcc BlockComponent.new(&block) 
    end

  end
end
