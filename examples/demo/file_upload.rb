class FileUploadTest < Wee::Component
  def render(r)
    r.file_upload.callback {|f| call Uploaded.new(f[:tempfile]) }
    r.break
    r.submit_button.name('Upload')
  end

  class Uploaded < Wee::Component
    def initialize(file)
      super()
      @file = file
    end

    def render(r)
      r.pre { r.encode_text @file.read }
      r.anchor.callback_method(:answer).with('back')
    end
  end
end
