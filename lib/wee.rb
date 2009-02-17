module Wee
  Version = "2.0.0"
end

module Wee::Examples; end

require 'wee/state'
require 'wee/callback'
require 'wee/context'
require 'wee/idgen'
require 'wee/renderer'

require 'wee/presenter'
require 'wee/decoration'
require 'wee/component'

require 'wee/core_ext'

require 'wee/application'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/components'

require 'wee/renderer/html/writer'
require 'wee/renderer/html/brushes'
require 'wee/renderer/html/canvas'
Wee::DefaultRenderer = Wee::HtmlCanvasRenderer
