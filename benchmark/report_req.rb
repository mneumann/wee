sum = 0.0

ARGV.each do |f|
  data = File.read(f)
  if data =~ /^Requests per second:\s+(\d+.\d+)/
    sum += 1/$1.to_f
  else
    raise "no req/sec found"
  end
end

puts 1/sum
