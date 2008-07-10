module ActiveMessaging
  
  # Keeps track of Adapters for various messaging systems. 
  # TODO implement a configure class that will handle broker.yml hashes
  # Currently no support for per-environment broker configuration.
  class BrokerRegistry < BaseRegistry    
    def create_item( name, *args )
      BrokerReference.new( name, *args)        
    end
  end

  class BrokerReference
    
    attr_reader :name
    
    def initialize( broker, *args )
      @name = broker
      @adapter = nil
      @config = args
    end
    
    # Were we able to load the adapter? If false the adapter is broken and
    # can't be used.
    def ok?
      ! adapter.nil?
    end
    
    # Reference to underlying adapter class. Handles loading and initialization.
    def adapter
      if @adapter.nil?
        
        # initialize the adapter
        class_name = @name.to_s.camelcase
        LOG.info "Attempting to load adapter #{class_name}."
        a = init_adapter( class_name )
        if a.nil?
          LOG.warn "Attempting to load adapter file."
          load_adapter( @name )
          a = init_adapter( "Adapters::#{class_name}")
        end
        
        # configure the adapter
        unless a.nil?
          begin
            a.configure(*@config)
          rescue NoMethodError
            LOG.warn "Adapter #{a.class} lacks a configure method."
          rescue ArgumentError => error
            LOG.error "Bad arguments when configuring #{a.class}.\n\t#{error}"
          end
        end
        @adapter = a        
      end
      @adapter
    end

    private

    def adapter_file( name )
      File.join(File.expand_path(File.dirname( __FILE__)), 'adapters', name)
    end

    def load_adapter( name )
      begin
        file = adapter_file( name.to_s ) 
        load file 
      rescue LoadError => error  
        LOG.warn "Unable to load adapter from #{file}.\n\t#{error}"
      end
    end
  
    def init_adapter( class_name )
      begin
        return class_name.constantize.new
      rescue NameError
        LOG.warn "Could not initialize adapter class #{class_name}."
      rescue ArgumentError
        Log.error "#{class_name} adapter needs a no arg constructor."
      end
    end
    
  end
  
end