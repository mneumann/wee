module Wee

  class ExternalResource
    def initialize(mount_path=nil)
      @mount_path = mount_path || "/" + self.class.name.to_s.downcase.gsub("::", "_")
    end

    def install(builder)
      rd = resource_dir()
      builder.map(@mount_path) do
        run Rack::File.new(rd)
      end
    end

    def javascripts
      []
    end

    def stylesheets
      []
    end

    protected

    def resource_dir
      raise
    end

    def file_relative(_file, *subdirs)
      File.expand_path(File.join(File.dirname(_file), *subdirs))
    end

    def mount_path_relative(*paths)
      paths.map {|path| "#{@mount_path}/#{path}"}
    end

  end # class ExternalResource

end
