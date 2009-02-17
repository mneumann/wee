module Wee

  #
  # Abstract base class of all id generators.
  #
  class IdGenerator
    def next
      raise "subclass responsibility"
    end
  end

  #
  # Sequential id generator.
  #
  # Returned ids are guaranteed to be unique, but they are easily guessable.
  #
  class IdGenerator::Sequential < IdGenerator
    def initialize(initial_value=0)
      @value = initial_value - 1
    end

    def next
      @value += 1
    end
  end

  #
  # Returned ids are unique with a very high probability and it's
  # very hard to guess the next or any used id.
  #
  class IdGenerator::Secure < IdGenerator

    require 'digest/sha1'
    begin
      require 'securerandom'
    rescue LoadError
    end

    def initialize(salt='wee')
      @salt = salt
    end

    def next_sha1
      now = Time.now
      dig = Digest::SHA1.new
      dig.update(now.to_s)
      dig.update(now.usec.to_s)
      dig.update(rand(0).to_s)
      dig.update($$.to_s)
      dig.update(@salt.to_s)
      dig.hexdigest
    end

    def next_secure
      SecureRandom.hex
    rescue NotImplementedError
      next_sha1
    end

    if defined?(SecureRandom)
      alias next next_secure
    else
      alias next next_sha1
    end

  end

end # module Wee
