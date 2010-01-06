require 'wee/component'

module Wee
  class Dialog < Component; end

  #
  # Abstract class
  #
  class FormDialog < Dialog
    def initialize(caption)
      @caption = caption
    end

    def render(r)
      r.div.css_class('wee').with {
        render_caption(r)
        render_form(r)
      }
    end

    def render_caption(r)
      r.h3 @caption if @caption
    end

    def render_form(r)
      r.form.with {
        render_body(r)
        render_buttons(r)
      }
    end

    def render_body(r)
    end

    def render_buttons(r)
      return if buttons.empty?
      r.div.css_class('dialog-buttons').with {
        buttons.each do |title, return_value, sym, method|
          sym ||= title.downcase
          r.span.css_class("dialog-button-#{sym}").with {
            if method
              r.submit_button.callback_method(method).value(title)
            else
              r.submit_button.callback_method(:answer, return_value).value(title)
            end
          }
        end
      }
    end

    def buttons
      []
    end
  end # class FormDialog

  class MessageDialog < FormDialog
    def initialize(caption, *buttons)
      super(caption)
      @buttons = buttons
    end

    def buttons
      @buttons
    end
  end

  class InformDialog < FormDialog
    def buttons
      [['Ok', nil, :ok]]
    end
  end # class InformDialog

  class ConfirmDialog < FormDialog
    def buttons
      [['Yes', true, :yes], ['No', false, :no]]
    end
  end # class ConfirmDialog

  class SingleSelectionDialog < FormDialog
    attr_accessor :selected_item

    def initialize(items, caption=nil, selected_item=nil)
      super(caption)
      @items = items
      @selected_item = selected_item
    end

    def state(s) super
      s.add_ivar(self, :@selected_item)
    end

    def render_body(r)
      r.select_list(@items).selected(@selected_item).callback_method(:selected_item=)
    end

    def buttons
      [['Ok', nil, :ok, :ok], ['Cancel', nil, :cancel, :cancel]]
    end

    def ok
      answer @selected_item
    end

    def cancel
      answer nil
    end
  end # class SingleSelectionDialog

  #
  # Extend class Component with shortcuts for the dialogs above
  #
  class Component
    def confirm(question, &block)
      call! ConfirmDialog.new(question), &block
    end

    def inform(message, &block)
      call! InformDialog.new(message), &block
    end

    def choose_from(items, caption=nil, selected_item=nil, &block)
      call! SingleSelectionDialog.new(items, caption, selected_item), &block
    end
  end # class Component

end # module Wee
