# This is a Rails-like scaffolder for use with Og (http://navel.gr/nitro)
# domain objects.

class OgScaffolder < Wee::Component
  def initialize(domain_class)
    super()
    @domain_class = domain_class
    @props = @domain_class.__props.reject {|a| a.name == 'oid'}
  end

  def render
    r.h1 "List #{ @domain_class }"
    r.paragraph
    r.table.border(1).with {
      render_header
      render_body
    }
    r.paragraph
    r.anchor.callback(:add).with("Add new #{ @domain_class }")
  end

  def render_header
    r.table_row.with {
      @props.each {|prop|
        render_property_header(prop)
      }
      render_action_header
    }
  end

  def render_action_header
    r.paragraph
    r.table_header.with { r.space(2) }  # the action column
  end

  def render_property_header(prop)
    r.table_header.with {
      r.bold(prop.name.to_s.capitalize)
    }
  end

  def render_body
    domain_objects.each {|obj| render_object(obj) }
  end

  def render_object(obj)
    r.table_row {
      @props.each {|prop| render_property(obj, prop) } 
      render_action(obj)
    }
  end

  def render_action(obj)
    r.table_data.with {
      r.anchor.callback(:edit, obj).with("Edit")
      r.space
      r.anchor.callback(:destroy, obj).with("Destroy")
    }
  end

  def render_property(obj, prop)
    r.table_data(obj.send(prop.name).to_s)
  end

  def edit(obj)
    call editor_for(obj)
  end

  def add
    call editor_for(@domain_class.new)
  end

  def destroy(obj)
    call Wee::MessageBox.new('Do you really want to destroy the object?'), 
      :confirm_destroy, obj
  end

  def confirm_destroy(obj, confirmed)
    obj.delete! if confirmed
  end

  def domain_objects
    @domain_class.all || []
  end

  def editor_class
    Editor
  end

  def editor_for(obj)
    editor_class.new(obj).add_decoration(Wee::FormDecoration.new)
  end
end

class OgScaffolder::Editor < Wee::Component

  def initialize(domain_object)
    super()
    @domain_object = domain_object
  end

  def render
    render_header
    each_property {|prop| 
      unless prop.name == 'oid'
        render_label(prop)
        render_property(prop) 
      end
    }
    render_buttons
  end

  def render_header
    action =
      if @domain_object.oid.nil?
        "Create"
      else
        "Edit"
      end

    r.h1 "#{ action } #{ @domain_object.class }"
  end

  def render_property(prop)
    if prop.klass.ancestors.include?(Numeric)
      render_numeric(prop)
    elsif prop.klass.ancestors.include?(String)
      render_string(prop)
    elsif prop.klass.ancestors.include?(TrueClass)
      render_bool(prop)
    elsif prop.klass.ancestors.include?(Date)
      render_date(prop)
    end
  end

  def render_numeric(prop)
    r.text_input.value(get_value_of(prop)).callback(:set_value_of, prop) 
  end

  def render_string(prop)
    if prop.meta[:ui] == :textarea
      r.text_area.callback(:set_value_of, prop).with(get_value_of(prop))
    else
      r.text_input.value(get_value_of(prop)).callback(:set_value_of, prop)
    end
  end

  def render_bool(prop)
    selected = get_value_of(prop) ? true : false
    r.select_list([true, false]).labels(["Yes", "No"]).selected(selected).
      callback {|choosen| set_value_of(prop, choosen) }
  end

  require 'date'
  def render_date(prop)
    t = get_value_of(prop) || Time.now
    
    m = Date::MONTHS.invert
    months = (1..12).map {|i| m[i].capitalize}
    r.select_list((t.year-10 .. t.year+10).to_a).selected(t.year).callback {|year| set_date_of(prop, year, :year) }
    r.space
    r.select_list((1..12).to_a).labels(months).selected(t.month).callback {|month| set_date_of(prop, month, :month) }
    r.space
    r.select_list((1..31).to_a).selected(t.day).callback {|day| set_date_of(prop, day, :day) }
  end

  def render_buttons
    r.paragraph
    r.submit_button.value('Save').callback(:save)
    r.space
    r.submit_button.value('Cancel').callback(:cancel)
  end

  def render_label(prop)
    r.paragraph
    r.text prop.name.capitalize
    r.break
  end

  private

  def each_property(&block)
    @domain_object.class.__props.each(&block)
  end

  def save
    @domain_object.save!
    answer @domain_object
  end

  def cancel
    answer nil
  end

  def get_value_of(prop)
    @domain_object.send(prop.symbol)
  end

  def set_value_of(prop, value)
    @domain_object.send(prop.symbol.to_s + "=", value)
  end

  def set_date_of(prop, val, pos)
    v = get_value_of(prop) || Date.new
    new_date = [v.year, v.month, v.day]
    pos = 
      case pos
      when :year then 0
      when :month then 1
      when :day then 2
      else raise
      end
    new_date[pos] = val
    set_value_of(prop, Date.new(*new_date))
  end

end
