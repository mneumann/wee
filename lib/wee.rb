module Wee
  Version = "0.8.0"
  LibPath = File.dirname(__FILE__)
end

require 'wee/core'
require 'wee/core_ext'

require 'wee/context'
require 'wee/application'
require 'wee/requesthandler'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/components'
require 'wee/snapshot_ext'

require 'wee/template'

require 'wee/renderer/html/writer'
require 'wee/renderer/html/brushes'
require 'wee/renderer/html/canvas'
Wee::DefaultRenderer = Wee::HtmlCanvasRenderer

require 'wee/idgen/simple'
require 'wee/idgen/md5'
