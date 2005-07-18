module Wee
  Version = "0.9.1"
  LibPath = File.dirname(__FILE__)
end

module Wee::Examples; end

require 'wee/core'
require 'wee/core_ext'

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

def Wee.run(component, add_page_decoration=true, mount_path='/app')
  require 'wee/utils'
  require 'wee/adaptors/webrick'

  component = component.new if component.kind_of?(Class)
  component.add_decoration(Wee::PageDecoration.new('Welcome to Wee!')) if add_page_decoration
  component.add_decoration(Wee::FormDecoration.new)
  Wee::WEBrickAdaptor.register(mount_path => Wee::Utils.app_for { component }).start
end
