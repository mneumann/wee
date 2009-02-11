class Wee::Page
  attr_accessor :id, :root_component, :snapshot, :callbacks

  def initialize(id, root_component, snapshot, callbacks)
    @id = id
    @root_component = root_component
    @snapshot = snapshot
    @callbacks = callbacks
  end

  # This method takes a snapshot from the current state of the root component
  # and returns it.

  def take_snapshot
    @root_component.decoration.backtrack_state(snap = Wee::Snapshot.new)
    return snap.freeze
  end

  # Render the root component with the given rendering context.

  def render(rendering_context)
    @root_component.decoration.render_on(rendering_context)
  end

  # This method processes the callbacks of the root component.
  #
  # Returns nil or a Response object in case of a premature response.
  
  def process_callbacks(ids_and_values)
    catch(:wee_abort_callback_processing) { 
      @callbacks.input_callbacks.with_triggered(ids_and_values) do
        @callbacks.action_callbacks.with_triggered(ids_and_values) do
          @root_component.decoration.process_callbacks(@callbacks)
        end
      end
      nil
    }
  end

end
