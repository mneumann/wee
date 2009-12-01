require 'wee/component'

module Wee

  class Task < Component

    def go
    end

    def render(r)
      r.session.send_response(RedirectResponse.new(r.url_for_callback(method(:go))))
    end

  end # class Task

end # module Wee
