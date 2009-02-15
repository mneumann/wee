class Wee::Page
  attr_accessor :id, :root_component, :snapshot, :callbacks

  def initialize(id, root_component, snapshot, callbacks)
    @id = id
    @root_component = root_component
    @snapshot = snapshot || take_snapshot()
    @callbacks = callbacks
  end

  # This method takes a snapshot from the current state of the root component
  # and returns it.

  def take_snapshot
    @root_component.decoration.backtrack_state(state = Wee::State.new)
    return state.freeze
  end

end
