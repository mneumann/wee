require 'og'

class OgApplication < Wee::Application
  attr_accessor :db
end

class OgSession < Wee::Session
  def awake
    application.db.get_connection
  end

  def sleep
    application.db.put_connection
  end
end

class OgScaffolder < Wee::Component
  def initialize(domain_class)
    super()
    @domain_class = domain_class
    @attributes = domain_class.__props.map {|a| a.name}.reject {|a| a == 'oid'}
  end

  def delete(obj)
    call Wee::MessageBox.new('Really delete?'), :confirm_delete, obj
  end

  def confirm_delete(confirmed, obj)
    obj.delete! if confirmed
  end

  def edit(obj)
    @edit = obj
  end

  def save(obj)
    obj.save!
    @edit = nil
  end
 
  def cancel
    @objs.delete(@edit)
    @edit = nil
  end

  def refresh
    @objs = @domain_class.all
  end

  def create
    @objs << (@edit =  @domain_class.new)
  end

  def render
    refresh if @objs.nil?

    r.h1 "#{ @domain_class } List"
    r.anchor.callback { refresh }.with("Refresh")

    r.form do
      r.table.border(1).with {
        r.table_row.headings(*@attributes.map{|a| a.capitalize}) {|h| r.bold(h)}
        @objs.each {|o| 
          r.table_row.with do 
            if @edit == o

              @attributes.each { |attr|
                r.table_data.with { r.text_input.callback {|v| o.send(attr+"=",v) }.value(o.send(attr)) }
              } 

              r.table_data.with {
                r.submit_button.callback { save(o) }.value("Save")
                r.space
                r.submit_button.callback { cancel() }.value("Cancel")
                r.space
                r.anchor.callback { delete(o) }.with("Delete")
              }

            else

              @attributes.each { |attr|
                r.table_data(o.send(attr))
              } 

              r.table_data.with {
                r.anchor.callback { edit(o) }.with("Edit")
                r.space
                r.anchor.callback { delete(o) }.with("Delete")
              }

            end
          end 
        }
      }
    end

    r.anchor.callback { create() }.with("Add new #{ @domain_class }")

  end

end

