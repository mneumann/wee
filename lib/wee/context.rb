class Wee::Context < Struct.new(:request, :response, :session, 
                                :callbacks, :document)
end
