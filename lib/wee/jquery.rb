require 'wee/external_resource'

class Wee::JQuery < Wee::ExternalResource
  def javascripts
    mount_path_relative('jquery-1.3.2.min.js', 'wee-jquery.js')
  end

  def resource_dir
    file_relative(__FILE__, 'jquery')
  end
end
