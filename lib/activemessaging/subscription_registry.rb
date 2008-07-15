module ActiveMessaging
  
  class SubscriptionRegistry < BaseRegistry
    
    def initialize( destination_registry, processor_registry )
      super()
      @destination_registry = destination_registry
      @processor_registry   = processor_registry
    end
    
    # Unlike the other registries, this one should not be called
    # externally. It populates itself by listening to the processor
    # and destination registries.
    private :register
    
    # Listens for destinations and processors added and automatically
    # adds subscriptions when appropriate.
    def update( command, object_ref )
      
      case command 
        when :add
        case object_ref
          
          when BaseDestination
          
          # Subscribe or re-subscribe all processors subscribed
          # to this destination.
          processors = @processor_registry.select do |p| 
            p.destination_name.to_sym == object_ref.name.to_sym
          end
          processors.each do |p|
            register object_ref, p
          end
          
          when ProcessorReference
          
          dest_name = object_ref.destination_name.to_sym
          destination = @destination_registry[dest_name]
          unless destination.nil?
            register destination, object_ref
          end
          
        end # case object_ref
      end # case command
    end # def update
        
    def create_item( *args )
      Subscription.new( *args )
    end
    
    def broker_names
      brokers.map{|b| b.to_sym}
    end
    
    def brokers
      @registry.values.map{|s| s.broker}.uniq
    end
    

    def processors_for( message )
      @registry.values.select{|s| message.route_to?(s.destination)}.
        map{|s| s.processor}.uniq
    end
    
  end
  
  
  class Subscription
    
    attr_reader :destination, :processor
    
    def initialize( destination, processor )
      @destination = destination
      @processor   = processor
    end
    
    def name
      "#{@destination.name}_#{@processor.name}".to_sym
    end
    
    # convenience methods
    def broker
      @destination.broker
    end
    
    def to_s
      "Subscription(:#{name})"
    end
    
  end
  
  
end