# Copyright by Kevin Howe (kh@newclear.ca)

$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/adaptors/webrick'
require 'wee/utils'
require 'date'

class Date
  # Fetch the number of days in the given month
  #
  def days_in
    ((Date.new(self.year, self.month, 1) >> 1)-1).day
  end
  # Calendar represenation of a month. Consists of a
  # list of weeks, each week a list of 7 days, each day a Date object.
  # Padded with days showing for previous and next month.
  #
  def calendar
    # months
    curr_month = Date.new(self.year, self.month, 1)
    prev_month = (curr_month << 1)
    next_month = (curr_month >> 1)

    # previous month days
    prev_days = Array.new
    prev_in_curr = curr_month.wday
    ((curr_month-1)-(prev_in_curr-1)).upto(curr_month-1) { |d| prev_days << d }

    # current month days
    curr_days = Array.new
    curr_month.upto(next_month-1) { |d| curr_days << d }
    
    # next month days
    next_days = Array.new
    days = prev_days+curr_days
    weeks = (days.size.to_f/7).ceil
    cdays_size = weeks*7
    next_in_curr = (cdays_size-days.size)
    next_month.upto(next_month+(next_in_curr-1)) { |d| next_days << d }
    days += next_days
    
    # split into weeks
    table = Array.new
    days.each do |day|
      table << Array.new if table.size == 0 or table.last.size == 7
      table.last << day
    end

    table
  end
end

# Generates a browsable calendar.
# Each day is linked, clicking will set the date to that particular day.
#
class MiniCalendar < Wee::Component

  # Browse mode: no answer will be given
  attr_accessor :browse

  # Holds the current chosen date
  attr_accessor :date

  # Initialize the MiniCalendar
  #
  def initialize(date=Date.today)
    super()
    @month = Date.new(date.year, date.month, 1)
    @day = date
    @browse = false
  end

  # Backtrack state
  #
  def backtrack_state(snap)
    super
    snap.add(self)
  end

  # Set to browse-only (no answer will be given)
  #
  def browse(value=true)
    @browse = (value && true)
    self
  end
  
  # True if in browser-only mode
  #  
  def browse?
    @browse
  end
  
  # True if the given date is the currently selected month
  #
  def current_month?(date)
    Date.new(date.year, date.month, 1) == @month
  end

  # True if the given date is the currently selected day
  #
  def selected_day?(date)
    date == @day
  end
  
  # Date object representing the previous month
  #
  def prev_month
    @month << 1
  end

  # Date object representing the next month
  #
  def next_month
    @month >> 1
  end
  
  # Previous month's abbreviation
  #
  def prev_month_abbr
    Date::ABBR_MONTHNAMES[prev_month.month]
  end
  
  # Next month's abbreviation
  #
  def next_month_abbr
    Date::ABBR_MONTHNAMES[next_month.month]
  end

  # String to be displayed as the month heading
  #
  def month_heading
    Date::MONTHNAMES[@month.month].to_s+' '+@month.year.to_s
  end
  
  # String to be displayed indicating the current date
  #
  def today_string
    date = Date.today
    mon_abbr = Date::ABBR_MONTHNAMES[date.month]
    day_abbr = Date::ABBR_DAYNAMES[date.wday]
    sprintf('Today is %s, %s %s %s', day_abbr, mon_abbr, date.day, date.year)
  end
  
  # Render a given day
  #
  def render_day(date)
    if current_month?(date)
      selected_day?(date) ? render_selected_day(date) : render_month_day(date)
    else
      render_other_day(date)
    end
  end
  
  # Render a day of the currently selected month
  #
  def render_month_day(date)
    r.table_data { r.anchor.callback { save(date) }.with(date.day) }
  end
  
  # Render the currently selected day
  #
  def render_selected_day(date)
    r.table_data.style('border: 1px solid black').with do
      r.anchor.style('font-weight: bold').callback { save(date) }.with(date.day)
    end
  end
  
  # Render days of the previous or next month
  #
  def render_other_day(date)
    r.table_data do
      r.anchor.style('color: silver').callback { save(date) }.with(date.day)
    end
  end
  
  # CSS styles
  #
  def render_styles
    # ...
  end
  
  # Render Calender header
  #
  def render_header
    r.table_row do
      r.table_header.colspan(4).with { r.encode_text(month_heading) }
      r.table_header { r.anchor.callback { go_prev }.with(prev_month_abbr) }
      r.table_header { r.anchor.callback { go_next }.with(next_month_abbr) }
      r.table_header { browse? ? r.space : r.anchor.callback { back }.style('color: black').with('X') }
    end
  end
  
  # Render Calendar footer
  #
  def render_footer
    r.table_row { r.table_header.colspan(7).with { r.encode_text(today_string) } }
  end
  
  # Render Calendar
  #
  def render
    r.html do
      r.head { r.title('Calendar'); render_styles }
      r.body do
        r.text(sprintf('<!--Month: %s, Day: %s-->', @month, @day))
        r.table { r.table_row { r.table_header {
          r.table do
            render_header
            r.table_row { Date::ABBR_DAYNAMES.each { |day| r.table_header(day) } }
            @month.calendar.each do |week|
              r.table_row do
                week.each { |day| render_day(day) }
              end
            end
            render_footer
          end
        }}}
      end
    end
  end
  
  # Return without changes
  #
  def back
    answer nil unless browse?
  end
  
  # Select the previous month
  #
  def go_prev
    @month = prev_month
  end
  
  # Select the next month
  #
  def go_next
    @month = next_month
  end
  
  # Save the given day
  #
  def save(day)
    @day = day
    @month = Date.new(day.year, day.month, 1)
    answer(day) unless browse?
  end
end

# Custom CSS styles
#
module StyleMixin
  def render_styles
    r.style("
      a {
        text-decoration: none;
      }
      body {
        font-size : 11px;
        font-family : Arial, Helvetica, sans-serif;
        text-align: center;
      }
      td {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 11px;
        border: 1px solid;
        background-color: #FFFFFF;
        vertical-align: top;
        text-align: center;
      }
      th {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 11px;
        font-style: normal;
        font-weight: bold;
        background-color: #BBCCFF;
        border: 1px solid;
        vertical-align: top;
        text-align: center;
      }
    ")
  end
end

# Calendar with custom CSS styles
#
class CustomCalendar < MiniCalendar
  include StyleMixin
end

# Calendar demo
#
class CustomCalendarDemo < Wee::Component
  include StyleMixin

  # Holds the current chosen date
  attr_accessor :date

  # Initialize with a Date object (defaults to today)
  #
  def initialize(date=Date.today)
    super()
    @date = date
  end
  
  # Backtrack state
  #
  def backtrack_state(snap)
    super
    snap.add(self)
  end

  # Render calendar icon
  #
  def render_icon
    icon = 'http://www.softcomplex.com/products/tigra_calendar/img/cal.gif'
    r.image.src(icon).width(16).height(16).border(0).alt('Calendar')
  end
  
  # Render Calendar demo
  #
  def render
    r.html do
      r.head { r.title('Calendar Demo'); render_styles }
      r.body do
        r.break
        r.table { r.table_row { r.table_header {
          r.table do
            r.table_row { r.table_header('Calendar Demo') }
            r.table_row { r.table_data {
              r.text_input.value(@date).attr(:date)
              r.space
              r.anchor.callback { calendar }.with { render_icon }
            }}
          end
        }}}
      end
    end
  end
  
  # Call the calendar component
  #
  def calendar()
    call( CustomCalendar.new(@date), :set_date)
  end

  def set_date(date)
    @date = date if date
  end
end
