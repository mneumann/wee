# Represents a request.
# 
# NOTE that if there are fields named "xxx" and "xxx.yyy", the value of
# fields['xxx'] is a Hash {nil => val of "xxx", 'yyy' => val of 'xxx.yyy'}.
# This is for the image-button to work correctly.

class Wee::Request

  DELIM = '/___/'

  attr_accessor :request_handler_id
  attr_reader :page_id, :fields, :cookies

  # The part of the URL that is user-defineable
  attr_accessor :info

  def initialize(app_path, path, headers, fields, cookies)
    raise ArgumentError if app_path[-1] == ?/
    @app_path, @path, @headers, @cookies = app_path, path, headers, cookies
    parse_fields(fields)
    parse_path
  end

  def application_path
    @app_path
  end

  # Is this an action request?
  def action?
    not render?
  end

  # Is this a render request?
  def render?
    self.fields.empty?
  end

  def build_url(hash={})
    default = {
      :request_handler_id => self.request_handler_id,
      :page_id => self.page_id,
      :info => self.info
    }
    hash = default.update(hash)

    request_handler_id = hash[:request_handler_id]
    page_id = hash[:page_id]
    callback_id = hash[:callback_id]
    info = hash[:info]

    raise ArgumentError if request_handler_id.nil? and not page_id.nil?
    if not pageless?
      raise ArgumentError if page_id.nil? and not callback_id.nil?
    end

    # build request path, e.g. /___/req-id/page-id
    req_path = make_request_path(request_handler_id, page_id)

    # build the whole url
    url = ""
    url << @app_path

    raise if url[-1] == ?/  # sanity check

    if info
      url << '/'
      url << info
    end
    url << req_path 

    url << '/' if info.nil? and req_path.empty? 

    url << ('?' + callback_id) if callback_id

    return url
  end

  private

  def pageless?
    false
  end

  def make_request_path(request_handler_id, page_id)
    arr = [request_handler_id, page_id].compact
    req_path = 
    if arr.empty?
      ""
    else
      DELIM + arr.join('/')
    end
  end

  def parse_fields(fields)
    fields ||= Hash.new
    @fields = Hash.new

    # sorted by decreasing key length, e.g. "2.x" comes before "2"
    fields.keys.sort_by {|k| -k.length}.each do |key|
      val = fields[key] 
      if key.include?(".")
        a, b = key.split(".", 2)
        @fields[a] ||= Hash.new
        @fields[a][b] = val 
      else
        if @fields.has_key?(key)
          @fields[key][nil] = val
        else
          @fields[key] = val
        end
      end
    end
  end

  def parse_path
    full_app_path, req_path = @path.split(DELIM, 2)

    if full_app_path == @app_path
      @info = nil
    elsif full_app_path[0, @app_path.size] == @app_path and full_app_path[@app_path.size] == ?/
      @info = full_app_path[@app_path.size+1..-1] 
    else
      raise "dispatched to wrong handler" 
    end

    @request_handler_id = @page_id = nil
    @request_handler_id, @page_id = req_path.split('/', 2) if req_path
  end

end
