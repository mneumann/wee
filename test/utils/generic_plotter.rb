require 'utils/gnuplot'

class GenericPlotter
  def initialize(interval, dataset_configs)
    @interval = interval
    @datasets = dataset_configs
    @datasets.each_with_index {|cfg, i|
      cfg[:params] ||= 'with lines'
      cfg[:title] ||= i.to_s
      cfg[:data] ||= []
    }
    @gnuplot = GnuPlot.spawn
  end

  def run
    Thread.start {
      @time = 0
      loop do
        @datasets.each do |cfg|
          cfg[:proc].call(cfg[:data], @time) 
        end
        @gnuplot.plot(@datasets)
        sleep @interval
        @time += @interval
      end
    }
  end
end
