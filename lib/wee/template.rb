class Wee::Presenter
  def self.template(method, hash={}) 
    method = method.to_s

    file_code = 
      if hash.has_key?(:property)
        "lookup_property(#{ hash[:property].inspect })"
      elsif hash.has_key?(:file)
        hash[:file].inspect
      elsif hash.has_key?(:local)
        # like file, but use relative to current path

        caller_path = caller.first.sub(/:\d+$/, "")

        File.join(File.dirname(caller_path), hash[:local]).inspect
      else
        caller_path = caller.first.sub(/:\d+$/, "")
        basename = caller_path[0, caller_path.rindex(".rb")]
        ext = '.tpl'

        if method =~ /^render(.*)$/
          basename + ext + $1.tr('_', '-')
        else
          raise ArgumentError
        end.inspect
      end

    if hash[:r_as_param]
      class_eval %{
        def #{ method }(r)
          r.template(#{ file_code })
        end
      }
    else
      class_eval %{
        def #{ method }
          r.template(#{ file_code })
        end
      }
    end
  end
end
