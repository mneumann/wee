module Wee
  Version = "2.0.0"
end

module Wee::Examples; end

require 'wee/state'
require 'wee/callback'
require 'wee/context'
require 'wee/renderer'

require 'wee/presenter'
require 'wee/decoration'
require 'wee/component'

require 'wee/application'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/html_writer'
require 'wee/renderer/html/brushes'
require 'wee/renderer/html/canvas'
Wee::DefaultRenderer = Wee::HtmlCanvasRenderer
