class Wee::Window < Wee::Component

  def initialize(title, pos, child)
    super()
    @title = title
    @child = child
    @status = :normal  
    @children = [@child]
    @pos = pos
  end

  def process_callbacks(callback_stream)
    return if @status == :closed
    super
  end

  def minimize
    @status = :minimized
  end

  def maximize
    @status = :normal
  end

  def close
    @status = :closed
  end

  def render_content_on(r)
    return if @status == :closed

    r.table.cellspacing(0).style("border:solid 1px grey; position: relative; top: #{@pos}; left: #{200+@pos.to_i}").with do
      r.table_row.style("background-color: lightblue; width: 100%").with do
        r.table_data.style("text-align: left; width: 66%").with(@title)
        r.table_data.style("text-align: right").with do
          if @status == :minimized
            r.anchor.action(:maximize).with("#")
          else
            r.anchor.action(:minimize).with("_")
          end
          r.space
          r.anchor.action(:close).with("X")
        end
      end
      r.table_row do
        r.table_data.colspan(2).with do
          r.render(@child) if @status == :normal
        end
      end
    end
  end

end
