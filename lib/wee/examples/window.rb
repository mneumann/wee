class Wee::Examples::Window < Wee::Component

  attr_accessor :title, :pos_x, :pos_y, :child

  def initialize(&block)
    super()
    @status = :normal  
    @pos_x, @pos_y = "0px", "0px"
    block.call(self) if block
  end

  def children
    [@child].uniq
  end

  def process_callbacks(&block)
    return if @status == :closed
    super
  end

  def render
    return if @status == :closed

    r.table.cellspacing(0).style("border:solid 1px grey; position: absolute; left: #{@pos_x}; top: #{@pos_y};").with do
      r.table_row.style("background-color: lightblue; width: 100%").with do
        r.table_data.style("text-align: left; width: 66%").with(@title)
        r.table_data.style("text-align: right").with do
          if @status == :minimized
            r.anchor.callback(:maximize).with("^")
          else
            r.anchor.callback(:minimize).with("_")
          end
          r.space
          r.anchor.callback(:close).with("x")
        end
      end
      r.table_row do
        r.table_data.colspan(2).with do
          r.render(@child) if @child and @status == :normal
        end
      end
    end
  end

  public 

  def minimize
    @status = :minimized
  end

  def maximize
    @status = :normal
  end

  def close
    @status = :closed
  end

end
