module ActiveMessaging
  
  class ProcessorRegistry < BaseRegistry
    
    def create_item( destination_name, processor, headers = {}, require_lib = nil)
      if processor.kind_of?(String)
        begin
          require(require_lib) unless require_lib.nil?
          processor_class = processor.constantize
        rescue NameError => e
          LOG.error "No class for processor. Asked for class #{processor}."
          raise BadConfigurationException, 
            "Could not locate processor class: #{processor}.\n\t#{e}"
        rescue LoadError => e
          LOG.error "Unable to load #{require_lib} when configuring processor "+
            "#{processor}. Please check your configuration."
          raise BadConfigurationException, "No file to load: #{require_lib}."
        end
      elsif processor.respond_to? :new
        processor_class = processor
      else
        raise ArgumentError, "The processor argument must be a String class " +
                             "name or the Class of the processor."
      end
      p = ProcessorReference.new( destination_name, processor_class, headers )
      p.validate!
    end
    
    def configure( options = {})
      return if options.nil?      
            
      LOG.debug "ProcessorRegistry received configuration message:\n\n" +
                "#{options.inspect}"
      
     # Do we have any brokers listed for the environment?
      entries = options[:processors]
      unless entries.respond_to?(:[]) && ! entries.empty?
        LOG.warn "No processor listed in processor configuration."
      else
        entries.each do |p|
          register p[:destination], p[:class], p[:headers], p[:require] if 
            p.has_key?(:destination) && p.has_key?(:class)
        end
      end
    end  
  end
  
  class ProcessorReference
    
    attr_reader :destination_name, :processor_class, :headers
    
    def initialize( destination_name , processor_class, headers = {})
      @destination_name = destination_name.to_sym
      @processor_class  = processor_class
      @headers          = ({} if headers.nil?) || headers.dup.freeze
      @instance         = nil
      @lock             = Mutex.new
    end
    
    def name
      "#{@destination_name}_#{@processor_class.name.underscore}".to_sym  
    end
    
    def validate!      
      raise ArgumentError, "Processors must respond to #process!" unless 
      processor_class.instance_methods.include?( 'process!' )      
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
      
      @lock.synchronize do # prevent multiple initializations  of reentrant processors        
        unless @instance             
          # Double-checked locking idiom. It may not be 100% reliable, 
          # as I don't know enough about underlying implementation of Ruby 
          # but it is better than nothing, I hope. 
          # http://www.cs.umd.edu/~pugh/java/memoryModel/DoubleCheckedLocking.html          
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
        end # unless
      end unless @instance # lock
            
      begin
       (@instance || instance).process!( message )
      ensure
        # only non-reentrant instances are torn down after the block
        instance.teardown if @instance.nil? && 
                             instance && instance.respond_to?(:teardown)
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