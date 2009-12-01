require 'wee/component'

module Wee

  class Task < Component

    def run
    end

    def render(r)
      r.session.send_response(RedirectResponse.new(r.url_for_callback(method(:run))))
    end

  end # class Task

end # module Wee
