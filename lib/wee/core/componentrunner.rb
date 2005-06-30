# Wee::ComponentRunner wraps a root component and provides methods that act on
# the components tree defined by the root component. 

class Wee::ComponentRunner

  # Values are parameters to method #process_callbacks_of

  DEFAULT_CALLBACK_PROCESSING = [
    # Invokes all specified input callbacks. NOTE: Input callbacks should never
    # call other components!
    [:input, true, false],

    # Invokes the first found action callback. NOTE: Only the first action
    # callback is invoked. Any other action callback is ignored.
    [:action, false, true],
    
    # Invoke live_update callback (NOTE: only the first is invoked).
    [:live_update, false, true]
  ]

  attr_accessor :root_component

  def initialize(root_component)
    @root_component = root_component
    @callback_processing = DEFAULT_CALLBACK_PROCESSING 
  end

  # This method takes a snapshot from the current state of the root component
  # and returns it.

  def snapshot
    @root_component.backtrack_state_chain(snap = Wee::Snapshot.new)
    return snap.freeze
  end

  # Render the root component with the given rendering context.

  def render(rendering_context)
    @root_component.do_render_chain(rendering_context)
  end

  # This method triggers several tree traversals to process the callbacks of
  # the root component.
  #
  # Returns nil or a Response object in case of a premature response.

  def process_callbacks(callback_stream)
    if callback_stream.all_of_type(:action).size > 1 
      raise "Not allowed to specify more than one action callback"
    end

    catch(:wee_abort_callback_processing) { 
      @callback_processing.each {|args| process_callbacks_of(callback_stream, *args) }
      nil
    }
  end

  protected

  def process_callbacks_of(callback_stream, type, pass_value=true, once=false)
    @root_component.process_callbacks_chain {|this|
      callback_stream.with_callbacks_for(this, type) { |callback, value|
        if pass_value
          callback.call(value)
        else
          callback.call
        end
        return if once
      }
    }
  end

end
