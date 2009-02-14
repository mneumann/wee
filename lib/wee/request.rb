require 'rack'

module Wee
  
  #
  # NOTE that if fields named "xxx" and "xxx.yyy" occur, the value of 
  # @fields['xxx'] is { nil => ..., 'yyy' => ... }. This is required
  # to make image buttons work correctly.
  #
  class Request < Rack::Request

    attr_reader :fields
    attr_accessor :request_handler_id
    attr_accessor :page_id

    def initialize(env)
      super(env)
      @fields = {}
      self.params.each {|key, val|
        if key.index(".") 
          prefix, postfix = key.split(".", 2)
          if @fields[prefix].kind_of?(Hash)
            @fields[prefix][postfix] = val
          else
            @fields[prefix] = { nil => @fields[prefix], postfix => val }
          end
        else
          if @fields[key]
            @fields[key][nil] = val
          else
            @fields[key] = val
          end
        end
      }

      @request_handler_id = @fields.delete("_s")
      @page_id = @fields.delete("_p")
    end

    # Is this an action request?
    def action?
      not render?
    end

    # Is this a render request?
    def render?
      @fields.empty?
    end

    include Rack::Utils

    def build_url(hash={})
      request_handler_id = hash[:request_handler_id] || @request_handler_id
      page_id = hash[:page_id] || @page_id
      callback_id = hash[:callback_id]
      info = hash[:info] || @info

      raise ArgumentError if request_handler_id.nil? and not page_id.nil?
      raise ArgumentError if page_id.nil? and not callback_id.nil?

      q = {}
      q['_s'] = request_handler_id if request_handler_id
      q['_p'] = page_id if page_id
      q[callback_id] = nil if callback_id 

      path = script_name() + (info || path_info())
      path << "?" << Rack::Utils.build_query(q) 

      return path
    end

  end # class Request

end
