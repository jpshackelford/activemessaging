module ActiveMessaging

  class DestinationRegistry < BaseRegistry
  
    def initialize( broker_registry )
      super
      @broker_registry = broker_registry
      @options = {}
    end
    
    def create_item( name, destination, publish_headers={}, broker=nil)
      
      broker_name = broker || @options[:default_broker] || :reliable_msg 
      b = @broker_registry[broker_name] # Get the real broker from the symbolic
                                        # broker name.

      raise BadConfigurationException, "No broker registered for :#{broker}." if 
        b.nil?

      raise TypeError, "Broker must respond to #create_destination" unless 
        b.respond_to?( :new_destination ) 

      b.create_destination( name, destination, publish_headers )      
    end    

    def configure(options = {})
      @options = options  
    end
    
  end

  class BaseDestination
    attr_reader :name, :destination, :publish_headers, :broker
    def initialize( name, destination, publish_headers, broker )
      @name = name
      @destination = destination
      @publish_headers = publish_headers
      @broker = broker
    end
  end
  
end
