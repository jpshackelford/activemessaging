module ActiveMessaging
  
  # Entry in BrokerRegistry.
  class Broker
    
    attr_reader :name
    
    def initialize( broker, options = {})
      @name = broker
      @adapter = nil
      @options = options if options.respond_to? :[]
      @options[:name] = @name
    end
    
    # Were we able to load the adapter? If false the adapter is broken and
    # can't be used.
    def ok?
      ! adapter.nil?
    end
    
    def adapter_name
      @options[:adapter] || @name
    end
    
    # Reference to underlying adapter class. Handles loading and initialization.
    def adapter
      if @adapter.nil?
        
        # initialize the adapter
        class_name = adapter_name.to_s.camelcase
        LOG.info "Attempting to load adapter #{class_name}."
        a = init_adapter( class_name )
        if a.nil?
          LOG.warn "Attempting to load adapter file."
          load_adapter( adapter_name )
          a = init_adapter( "ActiveMessaging::Adapters::#{class_name}")
          a = init_adapter( "Adapters::#{class_name}") if a.nil?
          a = init_adapter( class_name ) if a.nil?
        end
        
        # configure the adapter
        unless a.nil?
          begin
            a.configure(@options)
          rescue NoMethodError
            LOG.warn "Adapter #{a.class} lacks a configure method."
          rescue ArgumentError => error
            LOG.error "Bad arguments when configuring #{a.class}.\n\t#{error}"
          end
        end
        
        if a.nil?
          raise BadConfigurationException, "Adapter #{adapter_name.inspect} " +
            "unavailable.\n\tAdapter class #{class_name} does not appear to " +
            "be in the $LOAD_PATH:\n\t#{$LOAD_PATH.join("\n\t\t")}"
        end
        @adapter = a        
      end
      return @adapter
    end
    
    def poll_interval
      interval = 5 # Picking a number out of my hat. Hopefully the user or 
      # adapter will propose something they like better. 
      if @options.first.respond_to?( :[] ) &&
        interval = @options.first[:poll_interval]
      end
      if interval.nil? && @adapter.respond_to?(:poll_interval)
        interval = @adapter.poll_interval
      end
    end   
    
    def to_s
      "Broker(:#{@name}: #{adapter.class.name})"
    end
    
    private
    
    def adapter_file( name )
      File.join(File.expand_path(File.dirname( __FILE__)), 'adapters', "#{name}.rb")
    end
    
    def load_adapter( name )
      old_verbose = $VERBOSE
      $VERBOSE = false
      begin
        file = adapter_file( name) 
        load file 
      rescue LoadError => error  
        LOG.warn "Unable to load adapter from #{file}.\n\t#{error}"
      end
      $VERBOSE = old_verbose
    end
    
    def init_adapter( class_name )
      begin
        new_adapter = class_name.constantize.new
      rescue NameError
        LOG.debug "Could not initialize adapter class #{class_name}."
        return nil
      rescue ArgumentError
        LOG.error "#{class_name} adapter needs a no arg constructor."
        return nil
      else
        LOG.debug "Successfully initialized adapter #{new_adapter.class.name}"
        return new_adapter
      end
    end
  end
end