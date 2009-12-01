require "wee/conversation"

module Wee

  class IO
    def initialize(component)
      @component = component
    end

    def ask
      @component.display do |r|
        r.text_input.callback {|text| answer(text)}
        r.submit_button.value("Enter")
      end 
    end

    def pause(text)
      @component.display {|r| r.anchor.callback { answer }.with(text) }
    end

    def tell(text)
      @component.display {|r| r.text text.to_s }
    end
  end
end
