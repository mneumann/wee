class Wee::Presenter
  def self.template(method, hash={}) 
    method = method.to_s

    file_code = 
      if hash.has_key?(:property)
        "lookup_property(#{ hash[:property].inspect })"
      elsif hash.has_key?(:file)
        hash[:file].inspect
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

    class_eval %{
      def #{ method }
        r.template(#{ file_code })
      end
    }
  end
end
