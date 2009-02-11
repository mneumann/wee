require 'set'

class Wee::ComponentDispatcher < Wee::Component
  def initialize
    super()
    @rules = []
    @components = Set.new
  end

  def add_rule(pattern, component, &block)
    @components.add(component)
    @rules << [pattern, component, block]
  end

  def render_on(rendering_context)
    if component = match(session.current_context.request.info)
      component.decoration.render_on(rendering_context)
    end
  end

  def process_callbacks(&block)
    if component = match(session.current_context.request.info)
      component.decoration.process_callbacks(&block)
    end
  end

  def backtrack_state(snapshot)
    snapshot.add(@__decoration)
    @components.each do |component|
      component.decoration.backtrack_state(snapshot)
    end
  end

  protected

  def match(info)
    info ||= ""
    @rules.each do |pattern, component, block|
      if info =~ pattern
        block.call(component, $~) if block 
        return component 
      end
    end
    nil
  end
end
