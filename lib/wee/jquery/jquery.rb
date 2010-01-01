module Wee
  class JQuery
    FILES = %w(jquery-1.3.2.min.js wee-jquery.js)
    PUBLIC_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'public'))

    def self.install(mount_path, builder)
      builder.map(@mount_path = mount_path) do
        run Rack::File.new(Wee::JQuery::PUBLIC_DIR)
      end
    end

    def self.javascript_includes
      raise "JQuery.install needs to be called" unless @mount_path
      FILES.map {|f| "#{@mount_path}/#{f}" }
    end

    def self.render_javascript_includes(r)
      javascript_includes.each {|src| r.javascript.src(src) }
    end
  end
end
