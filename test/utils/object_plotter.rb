require 'utils/generic_plotter'

class ObjectPlotter < GenericPlotter
  def initialize(interval, *klasses)
    super(interval, klasses.map {|k| 
      {:title => k.to_s,# :params, 'with linespoints', 
       :proc => proc {|data, time| data << [time, ObjectSpace.each_object(k) {}] } }
    })
  end
end
