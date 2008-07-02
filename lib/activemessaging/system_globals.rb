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
    
    attr_accessor :logger, :selected_environment
    
    attr_writer :object_registry
                                
    def initialize
      # publicly accessible
      @logger = nil
      # private - Maintainers: these are private to keep the code simple. 
      #           Preserve encapsulation and avoid coupling!
      @selected_environment = nil
      @object_registry = {}    
    end
    
    def gateway
      @object_registry.gateway  
    end
    
    def processor_pool
      @object_registry.processor_pool
    end
    
    def start_poller
      unless @object_registry.poller && 
             @object_registry.poller.configured?             
        raise NotInitializedException.new("The system has not been properly " +
          "initialized. Use ActiveMessaging::Initializer#boot_server.")
      end
      @object_registry.poller.start
    end
    
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
    #     # configure brokers    
    #     my.broker_file '~/broker.yml'
    #     my.broker_hash {:development => {:adapter => :stomp }}
    #
    #     # configure destinations, filters, etc.
    #     my.destination :orders, '/queue/Orders'
    #     my.filter :some_filter, :only=>:orders
    #     my.processor_group :group1, :order_processor
    #
    #     # remove brokers, destinations, etc.
    #     my.waste_basket :destination, :orders
    #
    #     # global configuration
    #     my.config_hash {:brokers => {:development => {:adapter => :stomp }},
    #                     :destinations => {:orders => '/queue/Orders'}}
    #   end 
    #
    # Attempts to call #configure before system initialization (via Initializer)
    # is complete will result in a NotInitializedException.     
    def configure(config_hash = {})

      # Are ready to configure?
      raise NotInitializedException.new("Logger must be configured and an " +
        "environment selected.") unless @logger && @selected_environment 
      
      @object_registry.configure( config_hash )
    end
     
  end # class
end