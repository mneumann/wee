module Wee::Utils
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

  # Note that this method will load any file that matches the glob and in
  # modified since the method call, regardless whether it's loaded by the
  # current application or not. The glob is expanded only once at the initial
  # method call.

  def autoreload_glob(glob, check_interval=1)
    files = Dir.glob(glob)
    file_mtime = {}
    start_time = Time.now 
    Thread.new {
      loop do
        sleep check_interval 
        files.each do |file|
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
    }
  end

end
