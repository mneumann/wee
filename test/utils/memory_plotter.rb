require 'utils/measure_memory'
require 'utils/generic_plotter'

class MemoryPlotter < GenericPlotter
  def initialize(interval, *pids)
    super(interval, pids.map {|pid| 
      {:title => "pid: #{ pid }", :proc => proc {|data, time| data << [time, measure_memory(pid)] } }
    })
  end
end
