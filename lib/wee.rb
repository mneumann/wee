module Wee
  Version = "2.0.0"
end

require 'rack'

require 'wee/state'
require 'wee/callback'

require 'wee/presenter'
require 'wee/decoration'
require 'wee/component'

require 'wee/application'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/html_writer'
require 'wee/html_brushes'
require 'wee/html_canvas'

require 'wee/components/messagebox'
require 'wee/components/form_decoration'
require 'wee/components/page_decoration'

Wee::DefaultRenderer = Wee::HtmlCanvas
