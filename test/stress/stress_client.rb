require 'rubygems'
require 'mechanize'

class StressSession
  def initialize
    @agent = WWW::Mechanize.new {|a| 
      a.max_history = 1
    }
    @agent.get('http://localhost:2000/')
  end

  def click(val)
    link = @agent.page.links.find {|l| l.node.text == val}
    @agent.click(link)
  end

  def submit(val)
    form = @agent.page.forms.first
    button = form.buttons.find {|b| b.value == val}
    @agent.submit(form, button)
  rescue
    puts "invalid"
    p @agent.page
    p form
    sleep 5
  end

  def step
    %w(OK Cancel).each {|b|
      click('show')
      submit('OK')
      submit(b)
    }
    [%w(OK OK), %w(OK Cancel), %w(Cancel OK), %w(Cancel Cancel)].each {|b1, b2|
      click('show')
      submit('Cancel')
      submit(b1)
      submit(b2)
    }
  end
end

if __FILE__ == $0
  num_sessions = Integer(ARGV[0] || raise)
  puts "num_sessions: #{num_sessions}"

  sessions = (1..num_sessions).map { StressSession.new }
  loop do
    sessions.each {|s| s.step }
  end
end
