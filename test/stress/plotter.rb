class GnuPlot
  def self.spawn
    new(IO.popen("gnuplot", "w+"))
  end

  def initialize(port)
    @port = port
  end

  def plot(datasets)
    @port << "plot" 
    datasets.each_with_index do |h, i|
      @port << (i == 0 ? ' ' : ', ')
      @port << "'-' title '#{ h[:title] }' #{ h[:params] }" 
    end
    @port << "\n"

    datasets.each do |h|
      @port << h[:data].map{|v| v.join(" ")}.join("\n")
      @port << "\ne\n"
    end

    self
  end

  def exit
    @port << "exit\n"
    @port.close
    @port = nil
  end
end

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

class ObjectPlotter < GenericPlotter
  def initialize(interval, *klasses)
    super(interval, klasses.map {|k| 
      {:title => k.to_s,# :params, 'with linespoints', 
       :proc => proc {|data, time| data << [time, ObjectSpace.each_object(k) {}] } }
    })
  end
end

class MemoryPlotter < GenericPlotter
  def initialize(interval, *pids)
    super(interval, pids.map {|pid| 
      {:title => "pid: #{ pid }", :proc => proc {|data, time| data << [time, measure_memory(pid)] } }
    })
  end

  # return usage of process +pid+ in kb
  def measure_memory(pid=Process.pid)
    ["/proc/#{ pid }/status", "/compat/linux/proc/#{ pid }/status"].each {|file|
      return $1.to_i if File.exists?(file) and File.read(file) =~ /^VmSize:\s*(\d+)\s*kB$/
    }
    mem, res = `ps -p #{ pid } -l`.split("\n").last.strip.split(/\s+/)[6..7]
    return mem.to_i
  end
end
