class Wee::Context < Struct.new(:request, :response); end
class Wee::RenderingContext < Struct.new(:request, :response, :callbacks, :document); end
