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
