$LOAD_PATH.unshift '../lib'
require 'wee'
require 'wee/utils'
require 'wee/adaptors/webrick'

require 'components/page'

require 'components/calltest'
# for stressing continuations use this instead
#require 'components/calltest-cont'
#require 'wee/continuation'

File.open('pid', 'w+') {|f| f.puts $$.to_s }
app = Wee::Utils.app_for(CallTest, :page_cache_capacity => (ARGV.shift || 10).to_i)
Wee::WEBrickAdaptor.register('/app' => app).start
