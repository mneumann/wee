require 'fcgi'

Socket.do_not_reverse_lookup = true

# A FastCGI adaptor for Wee.
# 
# Depends on ruby-fcgi (http://raa.ruby-lang.org/list.rhtml?name=fcgi) or via
# Rubygems (gem install fcgi).
#
# Example of usage:
# 
#   require 'wee/adaptors/fastcgi'
#   Wee::FastCGIAdaptor.start('/app', application)
#
# == Setup FastCGI with Lighttpd
#
#   # lighttpd.conf
#   server.modules = (
#   "mod_fastcgi"
#   )
#   
#   fastcgi.server = (
#   "/app" =>
#     ( "fcgi" =>
#       (
#         "host" => 127.0.0.1",
#         "port" => 3000,
#         "check-local" => "disable"
#       )
#     )
#   )
# 
# Now start the Wee application (the file must be executable):
# 
#   spawn-fcgi -f ./run.rb -p 3000
#
# Finally start the lighttpd server:
# 
#   lighttpd -D -f lighttpd.conf
#

class Wee::FastCGIAdaptor
  def self.start(mount_path, application, request_class=Wee::Request)
    FCGI.each_cgi {|cgi|
      query = Hash.new

      # TODO: WEBrick like: return a string which has a to_list method!
      cgi.params.each {|k, v|
        raise if v.empty?
        obj = v.first
        obj.instance_variable_set("@__as_list", v)
        def obj.as_list() @__as_list end

        query[k] = obj
      } 

      # TODO
      header = []

      context = Wee::Context.new(request_class.new(mount_path, 
        cgi.script_name, header, query, cgi.cookies))

      application.handle_request(context)
      
      header = {}
      header['status'] = context.response.status.to_s

      context.response.header.each { |k,v| header[k] = v }
      if context.response.cookies?
        header['cookie'] = context.response.cookies
      end

      cgi.out(header) { context.response.content }
    }
  end
end
