module ActiveMessaging

  class DestinationRegistry < BaseRegistry
  
    def initialize( broker_registry )
      super()
      @broker_registry = broker_registry
    end
    
    # Note that newly created items in the destination registry are frozen
    # so that adapter implementers will not mistakenly use instance variables
    # but will maintain all state in thread local storage. 
    def create_item( name, destination, publish_headers={}, broker_name=nil)
      
      # Get the real broker from the symbolic broker name.
      b = @broker_registry[  broker_name ]                                       

      raise TypeError.new("Broker must respond to #new_destination") unless 
        b.adapter.respond_to?( :new_destination ) 

      dest = b.adapter.new_destination( name, destination, publish_headers )
      dest.validate!
      
      # This is done so that adapters will not attempt to to use instance 
      # variables to store state.        
      dest.freeze 
    end    

    def destination_names
      @registry.keys
    end
    
    def configure( options )
      entries = options[:destinations]
      entries.each_pair do |name,d|
        register( name, d[:destination], d[:headers], d[:broker])
      end
    end
    
  end

  # TODO Move this to base_adapter.rb along with an example of the 
  # adapter / broker class.
  #
  # Note that destinations must be re-entrant. Use thread-local storage via 
  # Thread.current instead of instance variables.   
  class BaseDestination
    
    attr_reader :name, :destination, :publish_headers, :broker
    
    def initialize( name, destination, publish_headers, broker )
      @name            = name.to_sym
      @destination     = destination
      @publish_headers = publish_headers || {}
      @broker          = broker
    end
    
    def send( message_body, message_headers={} )
      raise NotImplementedError, "Override #send / #publish in subclasses"
    end
    
    alias publish send
    
    def receive
      raise NotImplementedError, "Override #receive in subclasses"
    end
            
    def received( message, headers={})
      raise NotImplementedError, "Override #received in subclasses"
    end
        
    def unreceive message, headers={}
      raise NotImplementedError, "Override #unreceive in subclasses"
    end

    def to_s       
      "Destination(:#{@name} #{@destination} #{@broker})"
    end  
    
    def validate!
      if @destination.nil?     || @destination.empty? ||
         @publish_headers.nil? ||
         @broker.nil?
        raise BadConfigurationException, "Destination #{@name} was not " +
          "configured properly. Check the destination, headers, or broker " +
          "specified.\n\t#{self}"
      end
      return self
    end
    
  end
  
end
