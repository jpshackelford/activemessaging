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
      
      def message_is( class_name )
        @model_map = {} unless defined?(@model_map)
        if class_name.kind_of?( Class )          
          @model_map.store( self.name, class_name.name )
        elsif self.parent == self
        	@model_map.store( self.name, class_name.to_s ) 
        else
          @model_map.store( self.name, self.parent.name + '::' + class_name.to_s ) 
        end          
      end      
      
      def model_class
        @model_map[self.name].constantize
      end       
    end

    def logger()
      ActiveMessaging::LOG
    end
    
    # Override in sub-classes. Called once after initialization on #reentrant? 
    # processors and once before each #process! method on processors which are 
    # not reentrant.
    def setup      
    end
  
    # Override in subclasses. Called once at system shutdown on #reentrant? 
    # processors and once after each #process! method on processors which are 
    # not reentrant.
    def teardown      
    end
  
    # Implementors should override #on_model OR #on_message. The on_message 
    # event is handed the raw message body.
    def on_message( message )
      begin
        on_model( self.class.model_class.new( message ))
      rescue NameError
        raise NotImplementedError.new("Implement the on_message or on_model " + 
          "in your own processor class that extends ActiveMessaging::Processor")  
      end  
    end

    # Implementors should override #on_model OR #on_message. The on_model event
    # is handed an initialize object you define by setting up the class with a
    # message_is directive. The object should have a single argument constructor
    # which takes a message body.
    def on_model( model )
      raise NotImplementedError.new("Implement the on_model method in your own processor class that extends ActiveMessaging::Processor")
    end
    
    # Override in sub-classes
    def on_error( exception, message )
      raise exception
    end
  
    # Override in sub-classes where state is stored in the processor, i.e.
    # instance variables are used instead of strictly limiting methods to 
    # local variables.
    def reentrant?
      true
    end
  
    # Bind the processor to the current message so that the processor could
    # potentially access headers and other attributes of the message
    def process!( message )
      @message = message unless reentrant? == false
      return on_message( message.body )
    rescue Exception
      begin
        # for backward compatibility with older ActiveMessaging versions
        if method(:on_error).arity == 1
          on_error($!)
        else
          on_error($!, message )
        end
      rescue ActiveMessaging::AbortMessageException => rpe
        logger.error "Processor#process! - AbortMessageException caught."
        raise rpe
      rescue Exception => ex
        logger.error "Processor#process! - error in on_error, will propagate " +
          "no further: #{ex.message}"
      end
    end
  end
  

  
  # alias for compatibility
  Processor = BaseProcessor
  
end