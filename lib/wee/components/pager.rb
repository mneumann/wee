class Wee::Pager < Wee::Component
  attr_accessor :num_entries, :entries_per_page
  attr_reader :current_page

  def initialize(num_entries=0)
    super()
    @num_entries = num_entries
    @current_page = 0
    @entries_per_page = 20
    yield self if block_given?
  end

  # Returns the number of pages

  def num_pages
    n, rest = @num_entries.divmod(@entries_per_page)
    if rest > 0 then n + 1 else n end
  end

  # Returns the index of the first entry on the current page 

  def current_start_index
    @current_page * @entries_per_page 
  end

  # Returns the index of the last page

  def last_page_index
    num_pages() - 1
  end

  # Go to first page

  def first
    goto(0)
  end

  # Go to last page

  def last
    goto(last_page_index())
  end

  # Go to previous page
  
  def prev
    goto(@current_page - 1)
  end

  # Go to next page 

  def next
    goto(@current_page + 1)
  end

  # Go to page with index +page+
  # Note that page-indices start with zero!

  def goto(page)
    @current_page = page
    validate
  end

  def render
    return if num_pages() <= 0
    render_arrow(:first, "<<", "Go to first page"); r.space(2)
    render_arrow(:prev, "<", "Go to previous page"); r.space(2)
    render_index; r.space(2)
    render_arrow(:next, ">", "Go to next page"); r.space(2)
    render_arrow(:last, ">>", "Go to last page")
  end

  private

  def render_arrow(sym, text, tooltip=text)
    r.anchor.callback(sym).tooltip(tooltip).with { r.encode_text(text) }
  end

  def render_index
    last = last_page_index()
    (0 .. last).each do |i|
      if i == @current_page
        render_page_num(i, true)
      else
        render_page_num(i, false)
      end
      r.space if i < last
    end
  end

  def render_page_num(num, current)
    if current
      r.bold(num+1)
    else
      r.anchor.callback(:goto, num).with(num+1)
    end
  end

  def validate
    @current_page = [[0, @current_page].max, last_page_index()].min
  end
end
