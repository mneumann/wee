require 'wee/component'
require 'wee/external_resource'

module Wee

  #
  # A RootComponent has a special instanciate class method that makes it more
  # comfortable for root components.
  #
  class RootComponent < Component

    def self.run(*params, &block)
      Wee.run(self, *params, &block)
    end

    def title
      self.class.name.to_s
    end

    #
    # Returns an array of ExternalResource objects required for this
    # RootComponent.
    #
    def self.external_resources
      self.depends.flatten.select {|cls| cls <= Wee::ExternalResource }.uniq.
        map {|cls| cls.new }
    end

    def stylesheets
      self.class.external_resources.map {|ext_res| ext_res.stylesheets}.flatten
    end

    def javascripts
      self.class.external_resources.map {|ext_res| ext_res.javascripts}.flatten
    end

    def self.instanciate(*args, &block)
      obj = new(*args, &block)
      obj.add_decoration Wee::PageDecoration.new(obj.title, obj.stylesheets, obj.javascripts)
      return obj
    end

  end # class RootComponent

end # module Wee
