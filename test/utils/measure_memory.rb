# return usage of process +pid+ in kb
def measure_memory(pid=Process.pid)
  ["/proc/#{ pid }/status", "/compat/linux/proc/#{ pid }/status"].each {|file|
    return $1.to_i if File.exists?(file) and File.read(file) =~ /^VmSize:\s*(\d+)\s*kB$/
  }

  mem, res = `ps -p #{ pid } -l`.split("\n").last.strip.split(/\s+/)[6..7]
  return mem.to_i
end
