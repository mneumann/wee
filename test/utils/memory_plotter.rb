require 'utils/measure_memory'
require 'utils/gnuplot'

class MemoryPlotter
  def initialize(interval=5, *pids)
    @interval = interval
    @datasets = pids.map do |pid| 
      {:pid => pid, :title => "pid: #{ pid }", :params => 'with lines', :data => []}
    end
    @gnuplot = GnuPlot.spawn
  end

  def run
    Thread.start {
      t = 0
      loop do
        @datasets.each do |s|
          s[:data] << [t, measure_memory(s[:pid])]
        end

        @gnuplot.plot(@datasets)
        sleep @interval
        t += @interval
      end
    }
  end
end
