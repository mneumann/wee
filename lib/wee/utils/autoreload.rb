module Wee
  module_function

  def autoreload(check_interval=10)
    Thread.new(Time.now) {|start_time|
      file_mtime = {}
      loop do
        sleep check_interval 
        $LOADED_FEATURES.each do |feature|
          $LOAD_PATH.each do |lp|
            file = File.join(lp, feature)
            if (File.exists?(file) and 
              File.stat(file).mtime > (file_mtime[file] || start_time))
              file_mtime[file] = File.stat(file).mtime
              STDERR.puts "reload #{ file }"
              begin
                load(file)
              rescue Exception => e
                STDERR.puts e.inspect
              end
            end
          end
        end
      end
    }
  end
end
