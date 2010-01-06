require 'rack'

module Wee
  
  class Request < Rack::Request

    def self.new(env)
      env['wee.request'] ||= super 
    end

    attr_reader :fields
    attr_accessor :session_id
    attr_accessor :page_id

    def initialize(env)
      super(env)
      @fields = self.params
      @session_id = @fields.delete("_s")
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

    alias ajax? xhr?

    def build_url(hash={})
      session_id = hash.has_key?(:session_id) ? hash[:session_id] : @session_id
      page_id = hash.has_key?(:page_id) ? hash[:page_id] : @page_id
      callback_id = hash[:callback_id]
      info = hash.has_key?(:info) ? hash[:info] : @info

      raise ArgumentError if session_id.nil? and not page_id.nil?
      raise ArgumentError if page_id.nil? and not callback_id.nil?

      q = {}
      q['_s'] = session_id if session_id
      q['_p'] = page_id if page_id
      q[callback_id] = nil if callback_id 

      path = script_name() + (info || path_info())
      path << "?" << Rack::Utils.build_query(q) unless q.empty? 

      return path
    end

  end # class Request

end
