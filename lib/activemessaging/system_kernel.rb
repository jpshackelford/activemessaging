module ActiveMessaging
  
  # Provides access to system-wide functions and data. The Initializer handles
  # instantiation and assignment to ActiveMessaging::System from which it is 
  # ordinarily accessed. For example, to call the ActiveMessaging logger use:
  #   
  #   ActiveMessaging::System.logger.info "My logging message"
  # 
  # Ordinarily code which makes use of the ActiveMessaging API will not need to
  # access this directly since convenience methods are provided in base classes
  # which end users would ordinarily extend, e.g.  ActiveMessaging::Processor.
  
  class SystemKernel
    
    attr_reader :logger, :environment, :gateway
    
    # poller and registries can be configured without additional info
    # customizable elements are ThreadStrategy and ConnectionPool 
    
    def initialize
      self.logger = Logger.new(STDOUT)
      reset!
    end
    
    # Enough to send messages, but not to process them.
    def boot_client!
      unless @client_ready
        LOG.info "Preparing client library."
        
        # populate registries needed for client and expose them
        broker = BrokerRegistry.new
        dest   = DestinationRegistry.new( broker )      
        @registry.store(:broker,      broker)
        @registry.store(:destination, dest)      
        
        # setup the DSL for configuration
        @dsl = DSL.new( @registry )
        
        # other initialization
        @gateway = Gateway.new( @registry[:destination] ) 
        
        @client_ready = true
      end
    end
    
    # Message processing and poller
    def boot_server!
      unless @server_ready
        boot_client!
        LOG.info "Preparing server library."
        
        # populate registries needed for server and expose them
        procsr = ProcessorRegistry.new
        subsc  = SubscriptionRegistry.new( @registry[:destination], procsr )
        cust   = CustomClassRegistry.new
        
        @registry[:destination].add_observer( subsc )
        procsr.add_observer( subsc )
        
        @registry.store( :subscription, subsc )
        @registry.store( :processor,    procsr )
        @registry.store( :use_class,    cust )  
        
        # setup defaults for custom classes
        @dsl.use_class( :polling_strategy, ThreadPerBrokerStrategy )
        
        # listen for changes to CustomClassRegistry
        @registry[:use_class].add_observer( self )
        
        @poller  = nil
        @server_ready = true
      end
    end
    
    # Use the specified logger for all system functions.
    def logger=(logger)
      unless logger.respond_to?(:warn)  &&
        logger.respond_to?(:info)  &&
        logger.respond_to?(:debug) &&
        logger.respond_to?(:error) &&
        logger.respond_to?(:fatal)
        
        raise TypeError.new("Logger must support #fatal, #error, #warn, " + 
                                "#info, and #debug")
      end
      @logger = logger
      Kernel.silence_warnings do
        ActiveMessaging.const_set(:LOG, @logger)
      end      
    end
    
    # Assume we are running under the specified environment. 
    def environment=(selected_environment)
      @environment = selected_environment
    end
    
    # Obtain registry entries, esp. for testing.
    def registry_entry( registry, entry_name )
      r = @registry[ registry ]
      r[ entry_name ] if r
    end
    
    # Reset the system, including poller, registries, etc. Will attempt to stop
    # any running poller first.
    def reset!
      stop_poller if @poller
      @poller = nil
      @selected_environment = :production
      @client_ready = false
      @server_ready = false
      @registry = {}      
    end
    
    # Begin polling.
    def start_poller
      boot_server!
      LOG.debug "Initializing poller."
      @poller ||= Poller.new( polling_strategy )
      LOG.debug "Starting poller."
      @poller.start
    end
    
    # Stop polling
    def stop_poller
      unless @poller.nil?
        LOG.debug "Stopping poller."
        @poller.stop 
      end
    end
    
    # Reset poller strategy and connection manager if these
    # have been changed in the object registry.
    def update(command, item)
      unless @poller.running?
        @polling_strategy = nil
      end
    end
    
    private
    
    def polling_strategy
      if @polling_strategy.nil?
        strategy_class = @registry[:use_class][:polling_strategy]
        ps = strategy_class.new( @registry[:subscription] )
        @polling_strategy = ps 
      end 
      return @polling_strategy
    end
    
    public
    
    # == Usage
    #
    # Handles further configuration of the running system, especially defining
    # brokers, destinations, etc. Yields an instance of 
    # ActiveMessaging::ConfigurationDSL. Destinations, filters, etc. which have
    # been previously defined are reconfigured with the supplied information.
    # Use #waste_basket to remove previously defined items.
    #
    # Examples:
    #
    #   ActiveMessaging::System.configure do |my|
    #
    #     # configure destinations, filters, etc.
    #     my.destination :orders, '/queue/Orders'
    #     my.filter :some_filter, :only=>:orders
    #     my.processor_group :group1, :order_processor
    #
    #     # global configuration w/ a hash
    #     my.configuration {:broker => {:development => {:stomp => {} }},
    #                       :destination => {:orders => '/queue/Orders'} }
    #     
    #     # configuration with a file
    #     my.broker_configuration my.file('~/brokers.yml')
    #
    #   end 
    #
    # This method is thread-safe since it references objects which are
    # thread-safe, but note that each element of the configuration is applied
    # as it is executed so these configuration instructions could be interleaved
    # with configuration instructions applied on other threads, polling in
    # progress, etc.
    def configure
      boot_client!
      yield @dsl
    end
    
    # DSL for configuration of system. See SystemGlobals#configure.
    class DSL
      
      def initialize( registry )
        @r = registry
      end
      
      def method_missing( registry, *args )        
        # perhaps we are trying to configure a specific registry
        if registry =~ /^(.*)_configuration$/
          configure( $1, args.first )            
        end
        
        # perhaps we are referring to a registry
        if @r[registry]
          @r[registry].register(*args)
        else
          raise BadConfigurationException.new("Command [#{registry}] is not " +
            "available. If planning to run a poller, call #boot_server! first.")
        end        
      end
      
      def respond_to?( method, include_private )
        super(method, include_private) || ! @r[method].nil?
      end
      
      # Attempt to configure the system with the given hash.
      def configuration( hash )
        hash.each_pair do |reg_name, h|
          begin
            configure( reg_name, h )
          rescue BadConfigurationException  => e
            LOG.warn "Could not configure #{reg_name} with #{h.inspect}." + 
                     "\n\t#{e}\n\t#{e.backtrace.join("\t\n")}"        
          end
        end
      end
      
      # Load and parse the YAML configuration file specified by #config_file. The 
      # configuration file should contain a serialized Hash following the example
      # of #default. Class names may be specified as Strings may be substituted
      # rather than explicit class references as in #default.
      def file( config_file )
        unless File.exists?( config_file )
          raise BadConfigurationException, "No user defined configuration " + 
            "file found at #{config_file}."
        else
          begin
            config = YAML.load_file(config_file)
            unless config.respond_to? :[]
              raise BadConfigurationException, "YAML file expected to contain "+
                "a hash but did not. Fix #{config_file} and try again."        
            else
              return config.symbolize_keys!(:deep)
            end
          rescue Exception => e
            raise BadConfigurationException, "Failed to load user defined " +
              "configuration file #{config_file}.\n\t#{e}"
          end
        end        
      end
      
      # Read a broker.yml file and configure brokers accordingly
      def broker_yml( filename )
        config = file( filename )
        configure( :broker, :brokers => config )
      end

      private
      
      def registry( name )        
        @r[name.to_sym]
      end
      
      def configurable?( registry_name )
        begin
          r = registry( registry_name.to_sym )   # registry entry?
          m = r.method( :configure ) if r        # has configure method?
          if m && [1,-1,-2].include?( m.arity )  # method takes one argument?          
            return true
          else
            LOG.warn "No such registry for #{registry_name}." if r.nil?            
            LOG.warn "#configure must take an argument" if r && m
            return false
          end
        rescue NameError         
          LOG.warn "No #configure method for #{registry_name} registry " + 
            "(#{r.class.name})."
          return false
        end
      end
      
      def configure( registry_name, hash)
        if configurable?( registry_name )
          LOG.debug "Configuring #{registry_name}."
          registry( registry_name ).configure( hash )
        else
          raise BadConfigurationException, "Unable to configure #{registry_name}."
        end 
      end

    end # DSL class
    
    public
    
    def to_s
      self.class.name
    end
    
  end # SystemGlobals class
  
end