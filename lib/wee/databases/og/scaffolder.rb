# This is a Rails-like scaffolder for use with Og (http://navel.gr/nitro)
# domain objects.

class OgScaffolder < Wee::Component
  def initialize(domain_class)
    super()
    @domain_class = domain_class
    # DON'T use @properties here as it is already used by Wee
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
    call Editor.new(obj).add_decoration(Wee::FormDecoration.new)
  end

  def add
    call Editor.new(@domain_class.new, "Create").
      add_decoration(Wee::FormDecoration.new)
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
end

class OgScaffolder::Editor < Wee::Component

  def initialize(domain_object, action="Edit")
    super()
    @domain_object = domain_object
    @action = action
  end

  def render
    render_header
    each_property {|prop| 
      render_property(prop) unless prop.name == 'oid'
    }
    render_buttons
  end

  def render_header
    r.h1 "#{ @action } #{ @domain_object.class }"
  end

  def render_property(prop)
    render_label(prop)

    if prop.klass.ancestors.include?(Numeric)
      render_numeric(prop)
    elsif prop.klass.ancestors.include?(String)
      render_string(prop)
    elsif prop.klass.ancestors.include?(TrueClass)
      render_bool(prop)
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
    selected = [ get_value_of(prop) ? true : false ]
    r.select_list([true, false]).labels(["Yes", "No"]).selected(selected).
      callback {|choosen| set_value_of(prop, choosen.first) }
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

  def get_value_of(prop)
    @domain_object.send(prop.symbol)
  end

  def set_value_of(prop, value)
    @domain_object.send(prop.symbol.to_s + "=", value)
  end

  def save
    @domain_object.save!
    answer @domain_object
  end

  def cancel
    answer nil
  end
end
