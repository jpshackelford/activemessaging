module ActiveMessaging
  
  class NullIO
    def write(*args)
    end
    def close      
    end
  end
  
  NullLogger = Logger.new(NullIO.new)
  
end