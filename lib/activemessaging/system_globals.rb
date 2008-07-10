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
  
  class SystemGlobals
    
    attr_reader :logger, :environment
    
    # poller and registries can be configured without additional info
    # customizable elements are ThreadStrategy and ConnectionPool 
    
    def initialize
      
      @selected_environment = :production
      @logger = Logger.new(STDOUT)
      set_logger_constant( @logger )
      
      # populate registries and expose them
      @registry = create_registries
      
      # setup the DSL for configuration
      @dsl = DSL.new( @registry )
      
      # setup defaults for custom classes
      @dsl.use_class( :connection_manager, ConnectionManager )
      @dsl.use_class( :polling_strategy, ThreadPerBrokerStrategy )
      
      # listen for changes to CustomClassRegistry
      @registry[:use_class].add_observer( self )
      
      # other initialization
      @pooling_strategy = nil
      @connection_manager = nil
      @poller = nil
    end
    
    # Helper methods used in initialization routines.
    class << self
      
      def create_registries
        
        # initialize
        broker = BrokerRegistry.new
        dest   = DestinationRegistry.new( broker )
        subsc  = SubscriptionRegistry.new
        procsr = ProcessorRegistry.new
        cust   = CustomClassRegistry.new

        # listen
        subsc.add_observer( dest )
        subsc.add_observer( procsr )

        # return the registry
        r = { :broker       =>  broker,
              :destination  =>  dest,
              :subscription =>  subsc,
              :processor    =>  procsr,
              :use_class    =>  cust     }
              
        return r
      end
      
      def set_logger_constant( logger )
        Kernel.silence_warnings do
          ActiveMessaging.const_set(:LOG, logger)
        end
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
      self.class.set_logger_constant( @logger )
    end
    
    # Assume we are running under the specified environment. 
    def environment=(selected_environment)
      @environment = selected_environment
    end
    
    # Begin polling.
    def start_poller
      @poller ||= Poller.new( polling_strategy )
      @poller.start
    end
    
    # Stop polling
    def stop_poller
      @poller.stop unless @poller.nil?
    end
    
    # Reset poller strategy and connection manager if these
    # have been changed in the object registry.
    def update(command, item)
      unless @poller.running?
        @polling_strategy = nil
        @connection_manager = nil
      end
    end
    
    private
    
    def polling_strategy
      if @polling_strategy.nil?
        strategy_class = @registry[:use_class][:polling_strategy]
        ps = strategy_class.new( @registry[:subscription], connection_manager )
        @registry[:subscription].add_observer( ps )
        @polling_strategy = ps 
      end 
      return @polling_strategy
    end
    
    def connection_manager
      if @connection_manager.nil?
        conn_mgr_class = @registry[:use_class][:connection_manager]
        c = conn_mgr_class.new( @registry[:broker] )
        @registry[:broker].add_observer( c )
      end
      return @connection_manager
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
          raise BadConfigurationException, "No #{registry} to configure."
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
          rescue BadConfigurationException  
            LOG.warn "Could not configure #{reg_name} with #{h.inspect}."
          end
        end
      end

      # Load and parse the YAML configuration file specified by #config_file. The 
      # configuration file should contain a serialized Hash following the example
      # of #default. Class names may be specified as Strings may be substituted
      # rather than explicit class references as in #default.
      def file( config_file )
        unless File.exists?( config_file )
          LOG.info "No user defined configuration file found at " + 
                         "#{config_file}."
        else
          begin
            config = YAML.load_file(config_file)
            unless config.respond_to? :[]
              LOG.warn "YAML file expected to contain a hash but did not. "+ 
                             "Fix #{config_file} and try again."        
            else
              return config
            end
          rescue Exception => e
            LOG.warn "Failed to load user defined configuration file" + 
                           "#{config_file}.\n\t#{e}"
          end
        end        
      end
      
      private
      
      def registry( name )
        @r[registry_name.to_sym]
      end
      
      def configurable?( registry_name )
        if r = registry( registry_name ) &&      # registry exists
           m = r.method( :configure )    &&      # registry has configure method
           [1,-1,-2].include?( m.arity )         # method takes one argument          
          return true
        else
          return false
        end
      end
      
      def configure( registry_name, hash)
        if configurable?( registry_name )
          registry( registry_name ).configure( hash )
        else
          raise BadConfigurationException, "Unable to configure #{registry_name}."
        end 
      end
      
    end # DSL class
  end # SystemGlobals class
  
end