def measure_memory(pid=Process.pid)
  mem, res = `ps -p #{ pid } -l`.split("\n").last.strip.split(/\s+/)[6..7]
  return mem.to_i
end
