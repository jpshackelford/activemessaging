module ActiveMessaging
  
  class ProcessorRegistry < BaseRegistry
    
    def create_item( destination_name , processor_class, headers = {})
      p = ProcessorReference.new( destination_name, processor_class, headers )
      p.validate!
    end
    
  end
  
  class ProcessorReference
    
    attr_reader :destination_name, :processor_class, :headers, :options
    
    def initialize( destination_name , processor_class, headers = {})
      @destination_name = destination_name.to_sym
      @processor_class  = processor_class
      @headers          = headers.dup.freeze
      @instance         = nil
      @lock             = Mutex.new
    end
    
    def name
      @processor_class.name.underscore.to_sym  
    end
    
    def validate!      
      raise ArgumentError, "Processors must respond to #process!" unless 
      processor_class.new.respond_to?( :process! )      
      return self
    end
    
    # Process a message using the underlying #processor_class. Implements 
    # life cycle for reentrant processors and processors which must be 
    # initialized with each use. 
    #
    # Processors which respond to #reentrant? and return true will be 
    # initialized and Processor#setup only once. Such processors should be torn
    # down at system shutdown via #teardown. If the #processor_class is not 
    # reentrant, we initialize a new processor will every call and invoke   
    # Processor#setup and Processor#teardown before and after we invoke 
    # Processor#process! 
    def process!( message )
      instance = nil
      unless @instance        
        @lock.synchronize do # prevent multiple initializations
          # of reentrant processors
          begin 
            instance = @processor_class.new
            instance.setup if instance.respond_to?(:setup)
          rescue Exception > error
            LOG.error "Bad Processor: #{name}.\n\t#{error}\n\t#{error.backtrace}"
            raise BadProcessorError, "The processor #{name} could not be " +
            "initialized or setup."
          end          
          if instance.respond_to?(:reentrant?) && instance.reentrant?
            @instance = instance
          end          
        end # lock
      end      
      
      begin
       (@instance || instance).process!( message )
      ensure
        # only non-reentrant instances are torn down after the block
        instance.teardown if instance && instance.respond_to?(:teardown)
      end
    end
    
    # If #processor_class is reentrant, call #teardown on the initialized 
    # instance if defined. Call only on system shutdown. #setup is called by
    # #process! since processor instances are lazy-loaded.
    def teardown
      @lock.synchronize do
        @instance.teardown if @instance && @instance.respond_to?(:teardown)
      end
    end
    
    def to_s
      "ProcessorReference(:#{name} #{@destination_name} #{@processor_class.name})"
    end
    
  end
  
  
end