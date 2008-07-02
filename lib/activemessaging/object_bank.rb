module ActiveMessaging

  # Handles initialization, configuration, and access to configurable objects.
  class ObjectBank
    
    # Available options includes
    #  :logger - an instance of Logger 
    def initialize(options = {})
      @objects = {}
      @logger = options[:logger] || NullLogger
    end

    # Reference an object using the unique identifier associated with it at
    # the #create_objects call.
    def [](key)
      @objects[key]
    end
    
    # Initialize and add to the bank objects specified by config, using values
    # in defaults when an error occurs. The config and defaults parameters are
    # Hash objects the key of which is an identifier for the object and the 
    # values of which are either objects, classes, or a String class name.
    # Initialized objects are available by calling ObjectBank#<key> or 
    # ObjectBank#[](key). 
    def create_objects( config , defaults = {})
      config.each_pair do |section, klass|
        @logger.debug "Initializing object for [#{section}]."
        @objects[section] = safe_init(klass) || safe_init(default[section])
      end
    end
    
    def configure( config )    
    end
    
    def method_missing( method , *args)
      if @objects[method]
        return @objects[method]
      else
        raise NoMethodError.new("undefined method '#{method}' for #{self}")
      end
    end
    
    def respond_to?(symbol,include_private = false)
      super(symbol, include_private) || ! @objects[symbol].nil?
    end    

    # Handles further configuration of the running system, especially defining
    # brokers, destinations, etc. Call with config_hash or a block which yields 
    # an instance of ActiveMessaging::ConfigurationDSL. 
    def configure(config_hash = {})
        
      # yield and interpret the configuration block unless a hash is supplied
      if config_hash.empty?                      
        c = nil
        begin
          c = yield ActiveMessaging::ConfigurationDSL.new
        rescue NoMethodError => e
          @logger.error "Configuration in Error.\n\t#{e}"
        rescue ArgumentError => e
          @logger.error "Configuration in Error.\n\t#{e}"
        rescue BadConfigurationException => e
          @logger.error "Configuration in Error.\n\t#{e}"
        end
        config_hash = c.sections      
      end  
      
      # pass configuration data to each object in the registry
      config_hash.each_key do |section|
        o = @object_registry[section]
        unless o
          @logger.warn "Could not apply #{section} configuration because no " +
                       "object has been intialized for it."
        else
          begin
            config_data = config_hash[section]
            m = o.method(:configure_with)
            if m.arity == 1
              o.configure_with( config_data )
            elsif m.arity == 2
              o.configure_with( config_data, @selected_environment )
            else
              @logger.error "#{o.class}#configure_with must take one or two "+ 
                            "arguments."  
            end
          rescue NameError 
            @logger.error "#{o.class} must have a #configure_with method."
          rescue BadConfigurationException => e 
            @logger.error "An error occurred configuring the #{o.class}.\n\t#{e}"
          end        
        end # unless section        
        
      end # sections.each
    end # configure
          
    private
    
    # Returns a specified class if it can be loaded or nil. 
    # Can accept initialized objects, Classes, or Strings containing a fully
    # qualified class name.
    def safe_init( class_name )      
      begin
        o = nil
        if class_name.kind_of?(Class)
          o = class_name.new
          @logger.info "Initialized #{o.class}."
        elsif class_name.kind_of?(String)
          o = class_name.constantize.new
          @logger.info "Initialized #{o.class}."
        elsif class_name.kind_of?(Object)
          o = class_name
          @logger.info "An object of type #{o.class} required no " +
                              "further initialization."
        end
      rescue NameError => e
        @logger.warn "Unable to load class #{class_name}.\n\t#{e}"
      rescue NoMethodError
        @logger.warn "User specified class #{class_name} must have a " +
                              "#new method."        
      rescue ArgumentError => e
        @logger.warn "User specified class #{class_name} must have a " +
                              "no argument constructor.\n\t#{e}"
      ensure
        return o
      end
    end # safe_init
    
  end # ObjectBank 
end