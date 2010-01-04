$LOAD_PATH.unshift "../../lib"
require 'rubygems'
require 'wee'
require 'wee/locale'

class HelloWorld < Wee::RootComponent
  def render(r)
    r.h1 _("Hello World!")
    r.select_list(%w(en de)).selected(session.locale).labels(["English", "Deutsch"]).callback {|lang| session.locale = lang}
    r.submit_button.value(_("Set"))
  end
end

Wee::Application.load_locale("app", %w(en de), "en", :path => "locale", :type => :po)

HelloWorld.run if __FILE__ == $0
