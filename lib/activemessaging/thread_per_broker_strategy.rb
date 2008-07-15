module ActiveMessaging
  
  # Determine how we are going to divide the processor pool across threads.
  # This default implementation uses the same logic as has been used in the
  # past by ActiveMessaging: one thread per broker.  
  class ThreadPerBrokerStrategy
    
    def initialize( subscription_registry )
      @subscription_registry = subscription_registry
      @dispatcher = SingleThreadDispatcher.new( @subscription_registry )   
    end
    
    # Create new PollerThread for a given target thread id. 
    def create_thread( id )
      
      LOG.debug "Creating new thread [#{id}]."
      
      # one thread per broker, this broker matches the id
      broker = @subscription_registry.brokers.find{|b| b.to_sym == id}
      
      # create the iterator
      round_robin = RoundRobinIterator.new do
        subscriptions_by broker 
      end
      
      # the iterator should listen for changes
      @subscription_registry.add_observer( round_robin )
      
      # create the thread
      PollerThread.new( :name               => broker.to_sym,
                        :dispatcher         => @dispatcher,
                        :iterator           => round_robin,
                        :interval           => broker.poll_interval )
    end
    
    # Which threads do we expect to have running? Returns an Array of 
    # identifiers for the expected threads.
    def target_thread_identities
      @subscription_registry.broker_names
    end
    
    # Given a PollerThread, what is its id for purposes of comparison with
    # the results of #target_thread_identities
    def identify( thread )
      thread.name
    end
    
    def to_s
      self.class.name  
    end
    
    private
    
    def subscriptions_by( broker )
      @subscription_registry.select{|s| s.broker == broker}
    end
    
  end
end