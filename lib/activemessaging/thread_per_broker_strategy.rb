module ActiveMessaging
  
  # Determine how we are going to divide the processor pool across threads.
  # This default implementation uses the same logic as has been used in the
  # past by ActiveMessaging: one thread per broker.  
  class ThreadPerBrokerStrategy < BasePollingStrategy
    
    def initialize( subscription_registry )
      # overriding for clarity, no need to call #super
      @subscription_registry = subscription_registry
      @dispatcher = SingleThreadDispatcher.new( @subscription_registry )
      @thread_pool = nil
    end        
    
    # Create new PollerThread for a given target thread id.
    # Here id is a Symbol representing the name of an Adapter. 
    def create_thread( id )
      
      LOG.debug "Creating new thread [#{id}]."
      
      # one thread per broker, this broker matches the id
      broker = @subscription_registry.brokers.find{|b| b.name == id}
      
      # create the iterator
      round_robin = RoundRobinIterator.new do
        subscriptions_by broker 
      end
      
      # the iterator should listen for changes
      @subscription_registry.add_observer( round_robin )
      
      # create the thread
      PollerThread.new( :name              => broker.name,
                       :dispatcher         => @dispatcher,
                       :iterator           => round_robin,
                       :interval           => broker.poll_interval )
    end
    
    # Which threads do we expect to have running? Returns an Array of 
    # identifiers for the expected threads. Here we return a list of the 
    # brokers for which we have destinations and subscriptions.
    def target_thread_identities
      @subscription_registry.broker_names
    end
    
    private
    
    def subscriptions_by( broker )
      @subscription_registry.select{|s| s.broker == broker}
    end
    
  end
end