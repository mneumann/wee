#
# Cross product for Enumerable's
#

# TODO: use ** for [1,2,3].cross([4,5,6])

require 'generator'

module Enumerable
  def **(otherEnumerable)
    res = Array.new
    self.each do |i|
      otherEnumerable.each do |j|
        res << [i,j]
      end
    end
    return res
  end

  def cross(*enums, &block)
    Enumerable.cross(self, *enums, &block)
  end

  def self.cross(*enums, &block)
    raise if enums.empty?
    gens = enums.map{|e| Generator.new(e)}
    return [] if gens.any? {|g| g.end?}
    sz = gens.size
    res = []
    tuple = Array.new(sz)

    loop do
      # fill tuple
      (0 ... sz).each { |i| 
        tuple[i] = gens[i].current 
      }
      if block.nil?
        res << tuple.dup
      else
        block.call(tuple.dup)
      end

      # step forward
      gens[-1].next
      (sz-1).downto(0) { |i|
        if gens[i].end?
          if i > 0
            gens[i].rewind
            gens[i-1].next
          else
            return res
          end
        end
      }
    end
  end
end

if __FILE__ == $0
  p Enumerable.cross([1,2,3], [4], ["apple", "banana"])

  [1,2,3].cross([4,5,6]) {|elem| p elem }

  p Enumerable.cross([1,2], [3,4], [5,6], [7,8])
end
