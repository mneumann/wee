require 'wee'
require 'wee/examples/calculator'
require 'wee/examples/counter'

class Wee::Pager
  def render_arrow(sym, text, tooltip=text)
    index = 
    case sym
    when :first
      0
    when :prev
      @current_page - 1
    when :next
      @current_page + 1
    when :last
      last_page_index
    end
    r.anchor.info("pager/#{ index }").callback(sym).tooltip(tooltip).with { r.encode_text(text) }
  end

  def render_page_num(num, current)
    if current
      r.bold(num+1)
    else
      r.anchor.info("pager/#{ num }").callback(:goto, num).with(num+1)
    end
  end
end

comp = Wee::ComponentDispatcher.new
comp.add_rule /calc/, Wee::Examples::Calculator.new
comp.add_rule /pager\/(\d+)/, Wee::Pager.new(50) do |comp, match|
  comp.goto(Integer(match[1]))
end
comp.add_rule /(counter|)/, Wee::Examples::Counter.new

Wee.run(comp)
