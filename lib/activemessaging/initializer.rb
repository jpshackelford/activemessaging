module ActiveMessaging
  
  # == Usage
  #
  # Bootstrap ActiveMessaging for use in a Poller or in a client application
  # such as Rails or Merb. Use as follows:
  #
  #   init = ActiveMessaging::Initializer.new
  #   init.configure( init.load ( init.config_file ))
  #   init.boot_client # or  init.boot_server
  #                    #     ActiveMessaging::System.start_poller
  # 
  # == Configuring ActiveMessaging
  #
  # Initializer loads a configuration file which allows users to specify
  # alternative implementations of a number of core classes without altering
  # any framework code or subclassing the initializer. See #default for details.
  # If further customized initialization is required users may subclass the 
  # Initializer and provide alternative implementations for the following: 
  # * #default
  # * #config_file 
  # * #initialize_logger
  # * #initialize_environment_selection
  #
  # The poller is ordinarily booted and begins execution without any brokers or 
  # destinations defined. They are added to the running poller with calls to
  # ActiveMessaging::System.configure. (See ActiveMessaging::SystemGlobals).
  #
  # == Access to System-wide Settings 
  # 
  # ActiveMessaging is careful to limit class interdependencies and exposing   
  # data through globally accessible constants. Initializer configures an
  # instance of ActiveMessaging::SystemGlobals and assigns it to 
  # ActiveMessaging::System for global access to the ActiveMessaging::Gateway 
  # and ActiveMessaging::ProcessorPool. Since these classes are configured by
  # the Initializer and encapsulate the aspects of ActiveMessaging intended to
  # by publicly accessible, no provision is made for access of configuration
  # data. Maintainers are encouraged to add capability to the Initializer for 
  # subsystem components rather than to add visibility to internals via 
  # ActiveMessaging::SystemGlobals. 
  class Initializer
    
    def initialize 
      @config = ActiveMessaging::Hash.new
      @config.deep_merge!( default )  
      @system = SystemGlobals.new
      @system.logger = Logger.new(STDOUT)
      @object_registry = {}
    end
    
    def [](key)
      @config[key]  
    end
    
    # Merges the +config_hash+ with the existing configuration. Nested hashes
    # are also merged, but only one level deep.  Any String keys are converted
    # to symbols in the internal representation of the configuration.
    def configure( config_hash )
      @config.deep_merge!(config_hash)
    end        
    
    # Initial configuration used in absence of a configuration file.
    # Configuration files do not need to specify all of these values
    # as they will be merged with these. Don't forget to require libraries
    # containing custom classes referenced in the :object_registry or :logger
    # configuration elements. The :logger entry should be a string which can 
    # Safely be eval'd to return an object which responds to #fatal, #error, 
    # #warn, #info, #debug, etc. Also note that object_registry entries may be
    # object instances, classes, or class names. When specifying classes
    # be sure that they contain a no-argument constructor. 
    def default    
      {        
        :logger                 => "Logger.new(STDOUT)",
        :log_file               => '/var/log/am-poller.log',
        :config_file            => '/etc/am-poller.yml',
        :environment            => :production,        
        :object_registry        => 
        { :poller               => 'ActiveMessaging::Poller',
          :brokers              => 'ActiveMessaging::ConnectionManager',
          :destinations         => 'ActiveMessaging::DestinationRegistry',
          :processor_pool       => 'ActiveMessaging::ProcessorPool',
          :gateway              => 'ActiveMessaging::Gateway' },
        :object_config => {}
      }      
    end
    
    # Return the location of the configuration file. May be overridden by
    # subclasses wishing to locate the configuration file in a directory
    # following the convention of a particular framework such as Rails or ..
    def config_file
      f = ENV['AM_ENV'] || default[:config_file]
      File.expand_path(f)
    end
    
    # Load and parse the YAML configuration file specified by #config_file. The 
    # configuration file should contain a serialized Hash following the example
    # of #default. Class names may be specified as Strings may be substituted
    # rather than explicit class references as in #default.
    def load( config_file )
      unless File.exists?( config_file )
        @system.logger.info "No user defined configuration file found at " + 
                       "#{config_file}."
      else
        begin
          config = YAML.load_file(config_file)
          unless config.respond_to? :[]
            @system.logger.warn "YAML file expected to contain a hash but did not. "+ 
                           "Fix #{config_file} and try again."        
          else
            return config
          end
        rescue Exception => e
          @system.logger.warn "Failed to load user defined configuration file" + 
                         "#{config_file}.\n\t#{e}"
        end
      end
      
    end
    
    # Initialize client aspects of the framework for use with Rails, Merb, etc.
    # Provides access to the MessageSender mix-in for sending messages and to
    # the StorageAccessor mix-in for storage and retrieval of file-based data.  
    def boot_client
      initialize_logger
      initialize_environment_selection
      initialize_object_registry
      initialize_gateway
      initialize_object_configuration
      initialize_system_globals
    end
    
    # Initialize the framework for use in a polling daemon.
    def boot_server
      initialize_logger
      initialize_environment_selection
      initialize_object_registry      
      initialize_gateway
      initialize_poller             # <-- the only diff. between client & server
      initialize_object_configuration
      initialize_system_globals
    end
    
    # Initialize the logger. This method should be called by #boot_client or
    # by #boot_server but should not be called directly. 
    # May be overridden in subclasses to use the logger
    # of a specific application framework such as Rails or Merb. Any 
    # implementation should assign the logger to use to @system.logger.
    def initialize_logger
      begin
        
        case @config[:logger]
          when Logger
          new_logger = @config[:logger]
          when String
          new_logger = eval(@config[:logger])      
        end
        
        unless new_logger.respond_to?(:warn)  &&
          new_logger.respond_to?(:info)  &&
          new_logger.respond_to?(:debug) &&
          new_logger.respond_to?(:error) &&
          new_logger.respond_to?(:fatal)
          raise TypeError.new("Logger must support #fatal, #error, #warn, " + 
                                  "#info, and #debug")
        end
      rescue Exception => e
        @system.logger.warn "Failed to initialize configured Logger.\n\t#{e}"
      end
      @system.logger = new_logger
    end
    
    # Determines which environment we are running under for configuration of 
    # environment specific brokers.  This method should be called by 
    # #boot_client or by #boot_server but should not be called directly. May be 
    # overridden in subclasses. Any  implementation should assign 
    # @config[:environment] a lowercase symbol representing the environment
    # name. 
    def initialize_environment_selection
      if ENV['AM_ENV']
        @system.selected_environment = ENV['AM_ENV'].downcase.to_sym  
      end
      @system.selected_environment ||= default[:environment]       
    end
    
    # Initialize the object registry
    def initialize_object_registry      
      @system.logger.info "Initializing object registry."
      @object_registry = ObjectBank.new( :logger => @system.logger )
      @object_registry.create_objects(@config[:object_registry], default )                  
    end
    
    # Initialize the gateway which is used for sending and receiving messages
    # in both client and poller applications. This method should be called by 
    # #boot_client or by #boot_server but should not be called directly. There 
    # should be no need to override this method in subclasses as the gateway is
    # very basic. Once initialized @system.gateway contains the gateway.  
    def initialize_gateway
      
      # The connection manager needs access to the destination registry
      @object_registry[:brokers].destination_registry = 
        @object_registry[:destinations]
    
      # The gateway needs access to the destination registry
      @object_registry[:gateway].destination_registry = 
        @object_registry[:destinations]
      
      # The gateway needs access to the connection manager  
      @object_registry[:gateway].connection_manager = 
        @object_registry[:brokers]
    end  
        
    # Initialize (but do not start) the poller. This method should be called by 
    # #boot_client or by #boot_server but should not be called directly. 
    def initialize_poller
      @object_registry[:poller].destination_registry = 
        @object_registry[:destinations]
      
      @object_registry[:poller].connection_manager = 
        @object_registry[:brokers]
    end
    
    # Tells the object registry to configure each of its objects passing in 
    # configuration detail from the initial configuration.
    def initialize_object_configuration
      @object_registry.configure(@config[:object_config])
    end
    
    # Assign the ActiveMessaging::SystemGlobals object to 
    # ActiveMessaging::System for access by components of the running system.
    # Wrap-up and free up memory so that the initializer can be properly garbage
    # collected.    
    def initialize_system_globals
      
      # Give system command of object registry
      @system.object_registry = @object_registry
      
      # Assign the SystemGlobals object to ActiveMessaging::System
      Kernel.silence_warnings do
        ActiveMessaging.const_set(:System, @system.freeze)
      end      
      # Free up memory so that the initializer 
      # can be garbage collected.  
      @config = nil
      @object_registry = nil              
      @system = nil      
    end

    
  end # class
  
end # module