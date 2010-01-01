require 'wee/external_resource'

class Wee::RightJS < Wee::ExternalResource
  def javascripts
    mount_path_relative('rightjs-1.5.2.min.js', 'wee-rightjs.js')
  end

  def resource_dir
    file_relative(__FILE__, 'rightjs')
  end
end
