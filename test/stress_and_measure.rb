$LOAD_PATH.unshift '../lib'

require 'utils/memory_plotter'
require 'utils/cross'

require 'rubygems'
require 'mechanize'   # requires my mechanize gem

Socket.do_not_reverse_lookup = true

PID = ARGV.shift || raise
NUM_SESSIONS = (ARGV.shift || 10).to_i

MemoryPlotter.new(5, PID).run

class StressSession
  def initialize
    @agent = WWW::Mechanize.new {|a| 
      a.max_history = 1
    }
    @agent.get('http://localhost:2000/app')
  end

  def click(val)
    link = @agent.page.links.find {|l| l.node.text == val}
    @agent.click(link)
  end

  def submit(val)
    form = @agent.page.forms.first
    button = form.buttons.find {|b| b.value == val}
    @agent.submit(form, button)
  end

  def step
    %w(OK Cancel).each {|b|
      click('show')
      submit('OK')
      submit(b)
    }
    (%w(OK Cancel) ** %w(OK Cancel)).each { |b1, b2|
      click('show')
      submit('Cancel')
      submit(b1)
      submit(b2)
    }
  end
end

sessions = (1..NUM_SESSIONS).map { StressSession.new }
loop do
  sessions.each {|s| s.step }
end
