require 'wee'
require 'wee/utils'
require 'wee/adaptors/webrick'
require 'og'
require 'wee/databases/og'

# Database configuration
require 'conf/db.rb'

# Your components
require 'components/main'

# Your models
require 'models/recipe'


app = Wee::Utils.app_for(nil, :application => OgApplication,
   :session => OgSession) {
  Main.new.add_decoration(Wee::PageDecoration.new('Wee+Og'))
}
app.db = Og::Database.new(DB_CONFIG)
Wee::Utils::autoreload_glob('components/**/*.rb')
Wee::WEBrickAdaptor.register('/app' => app).start
