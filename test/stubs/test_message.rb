module ActiveMessaging #:nodoc:
  
  class TestMessage
    attr_reader :headers
    attr_accessor :body

    def initialize(destination, headers = {}, body = "")
      @headers, @body = headers, body
      @headers['destination'] = destination
    end
    
    def command
      "MESSAGE"
    end
  end

end