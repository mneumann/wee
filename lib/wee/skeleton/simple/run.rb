require 'wee'
require 'wee/utils'
require 'wee/adaptors/webrick'

# Your components 
require 'components/main'

app = Wee::Utils.app_for {
  Main.new.add_decoration(Wee::PageDecoration.new('Wee'))
}
Wee::Utils::autoreload_glob('components/**/*.rb')
Wee::WEBrickAdaptor.register('/app' => app).start
