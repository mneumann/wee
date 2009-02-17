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
      (@value += 1).to_s(36)
    end
  end

  #
  # Returned ids are unique with a very high probability and it's
  # very hard to guess the next or any used id.
  #
  class IdGenerator::Secure < IdGenerator

    require 'digest/md5'
    begin
      require 'securerandom'
    rescue LoadError
    end

    def initialize(salt='wee')
      @salt = salt
    end

    def next_md5
      now = Time.now
      dig = Digest::MD5.new
      dig.update(now.to_s)
      dig.update(now.usec.to_s)
      dig.update(rand(0).to_s)
      dig.update($$.to_s)
      dig.update(@salt.to_s)
      dig.digest
    end

    def next_secure
      SecureRandom.random_bytes(16)
    rescue NotImplementedError
      next_md5
    end

    def next
      str = defined?(::SecureRandom) ? next_secure : next_md5
      packed = [str].pack('m')
      packed.tr!("=\r\n", '')
      packed.tr!('+/', '-_')
      packed
    end

  end

end # module Wee
