# Returned ids might not be unique, but it should be very hard to guess the
# next id.

require 'digest/md5'

class Wee::Md5IdGenerator < Wee::IdGenerator
  def initialize(salt='wee')
    @salt = salt
  end

  def next
    now = Time.now
    md5 = Digest::MD5.new
    md5.update(now.to_s)
    md5.update(now.usec.to_s)
    md5.update(rand(0).to_s)
    md5.update($$.to_s)
    md5.update(@salt.to_s)
    md5.hexdigest
  end
end
