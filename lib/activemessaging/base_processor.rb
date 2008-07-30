# 'abstract' base class for ActiveMessaging processor classes
module ActiveMessaging

  class BaseProcessor
    include MessageSender
    
    attr_reader :message
  
    class<<self
      def subscribes_to destination_name, headers={}
        ActiveMessaging::System.boot_server!
        ActiveMessaging::System.configure do |my|
          my.processor destination_name, self, headers
        end
      end
      alias subscribe_to subscribes_to
    end

    def logger()
      ActiveMessaging::LOG
    end
    
    def on_message(message)
      raise NotImplementedError.new("Implement the on_message method in your own processor class that extends ActiveMessaging::Processor")
    end

    def on_error(exception)
      raise exception
    end
    
    # Bind the processor to the current message so that the processor could
    # potentially access headers and other attributes of the message
    def process!(message)
      @message = message
      return on_message(message.body)
    rescue Exception
      begin
        on_error($!)
      rescue ActiveMessaging::AbortMessageException => rpe
        logger.error "Processor#process! - AbortMessageException caught."
        raise rpe
      rescue Exception => ex
        logger.error "Processor#process! - error in on_error, will propagate no further: #{ex.message}"
      end
    end
  end
  
  def reentrant?
    true
  end
  
  # alias for compatibility
  Processor = BaseProcessor
  
end