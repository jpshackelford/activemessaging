module ActiveMessaging
  
  # Keeps track of Adapters for various messaging systems. 
  # TODO implement a configure class that will handle broker.yml hashes
  # Currently no support for per-environment broker configuration.
  class BrokerRegistry < BaseRegistry    
    
    def create_item( name, options = {} )
      Broker.new( name, options )        
    end
    
    def default_entry
      :reliable_msg
    end
    
    def configure(options = {})
      return if options.nil?      
            
      LOG.debug "BrokerRegistry received configuration message: " +
                "#{options.inspect}"
      
      env = ActiveMessaging::System.environment
      LOG.debug "Configuring brokers for environment [#{env.inspect}]."
      
      # Do we have any brokers listed for the environment?
      entries = options[:brokers]
      unless entries.respond_to?(:[]) && ! entries.empty?
        LOG.warn "No brokers listed in broker configuration."
        brokers = {}
      else
        brokers = entries[env]
        raise BadConfigurationException, "Environment entry [#{env}] does " + 
          "not appear in the broker configuration. Cannot register brokers." unless
          (brokers.respond_to?(:[]) && ! brokers.empty?) ||
           brokers.kind_of?( Symbol ) || brokers.kind_of?( String )
      end
      
      # Does the entry represent a single broker name, options for configuring  
      # a single broker, or multiple brokers?
      if brokers.kind_of?( Symbol ) || brokers.kind_of?( String )
      
        # adapter name, no options
        # e.g. :env1 => :adapter_stub
        register( brokers.to_sym ) 
      
      else brokers.respond_to? :[]      
        
        name = brokers[:name] || brokers[:adapter]
        
        # register one broker entry -- if only one
        # e.g :env2 => { :adapter => :adapter_stub, :opt1 => 1 }
        register( name, brokers ) unless name.nil?                  

        # register multiple broker entries -- if multiple
        #e.g. :env3 => { :broker1 => { :adapter => :adapter_stub, :opt1 => 1 },
        #                :broker2 => { :adapter => :adapter_stub, :opt1 => 1 } }
        brokers.each_pair do |name_, opts|        
          register( name_, opts)             
        end if name.nil?       
        
      end
      options.delete(:brokers)
      @options = options
    end
    
  end
end