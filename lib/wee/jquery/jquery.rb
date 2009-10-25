module Wee
  class JQuery
    FILES = %w(jquery-1.3.2.min.js wee-jquery.js)
    PUBLIC_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'public'))

    def self.install(mount_path, builder)
      builder.map(@mount_path = mount_path) do
        run Rack::File.new(Wee::JQuery::PUBLIC_DIR)
      end
    end

    def self.javascript_includes(r)
      raise "JQuery.install needs to be called" unless @mount_path
      FILES.each {|f| r.javascript.src("#{@mount_path}/#{f}") }
    end
  end
end
