module Wee
  Version = "2.2.0"
end

require 'rack'

require 'wee/state'
require 'wee/callback'

require 'wee/presenter'
require 'wee/decoration'
require 'wee/component'
require 'wee/root_component'
require 'wee/task'
require 'wee/dialog'

require 'wee/application'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/html_document'
require 'wee/html_brushes'
require 'wee/html_canvas'

if RUBY_VERSION >= "1.9"
  begin
    require 'continuation'
  rescue LoadError
  end
end

class Wee::HelloWorld < Wee::RootComponent
  def render(r)
    r.text "Hello World from Wee!"
  end
end

def Wee.run(component_class=nil, params=nil, &block)
  raise ArgumentError if component_class and block

  params ||= Hash.new
  params[:mount_path] ||= '/'
  params[:port] ||= 2000
  params[:public_path] ||= nil
  params[:additional_builder_procs] ||= []
  params[:use_continuations] ||= false
  params[:print_message] ||= false
  params[:autoreload] ||= false

  if component_class <= Wee::RootComponent
    component_class.external_resources.each do |ext_res|
      params[:additional_builder_procs] << proc {|builder| ext_res.install(builder)}
    end
  end

  raise ArgumentError if params[:use_continuations] and block

  unless block
    block ||= if params[:use_continuations]
      proc { Wee::Session.new(component_class.instanciate,
                 Wee::Session::ThreadSerializer.new) }
    else
      proc { Wee::Session.new(component_class.instanciate) }
    end
  end

  app = Rack::Builder.app do
    map params[:mount_path] do
      a = Wee::Application.new(&block)

      if params[:autoreload]
        if params[:autoreload].kind_of?(Integer)
          timer = Integer(params[:autoreload])
        else
          timer = 0
        end
        use Rack::Reloader, timer
      end

      if params[:public_path]
        run Rack::Cascade.new([Rack::File.new(params[:public_path]), a])
      else
        run a
      end
    end
    params[:additional_builder_procs].each {|bproc| bproc.call(self)}
  end

  if params[:print_message]
    url = "http://localhost:#{params[:port]}#{params[:mount_path]}"
    io = params[:print_message].kind_of?(IO) ? params[:print_message] : STDERR
    io.puts
    io.puts "Open your browser at: #{url}"
    io.puts
  end
  server = eval ("Rack::Handler::#{params[:server]}")
  server.run(app, :Port => params[:port])

#  Rack::Handler::WEBrick.run(app, :Port => params[:port])
end

#
# Like Wee.run, but for use with continuations.
#
def Wee.runcc(component_class, params=nil)
  params ||= Hash.new
  params[:use_continuations] = true
  Wee.run(component_class, params)
end


