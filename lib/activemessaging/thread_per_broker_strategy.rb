module ActiveMessaging
  
  # Determine how we are going to divide the processor pool across threads.
  # This default implementation uses the same logic as has been used in the
  # past by ActiveMessaging: one thread per broker.  
  class ThreadPerBrokerStrategy
    
    def initialize( options = {})
      @pool               = options[:processor_pool]
      @connection_manager = options[:connection_manager] 
      @dispatcher         = Dispatcher.new    
    end
    
    # Create new PollerThread for a given target thread id. 
    def create_thread( id )
      
      # create a destination scheduler for each thread
      broker = @pool.brokers.find{|b| b.name == id}
      
      round_robin = RoundRobinScheduler.new( 
        :pool_initializer => lambda{ destination_pool },
        :expiry_policy    => CallCountExpiryPolicy.new
      )
      
      # create the thread
      PollerThread.new( :name               => broker.name,
                        :dispatcher         => @dispatcher,
                        :connection_manager => connection_manager,
                        :scheduler          => round_robin,
                        :interval           => broker.interval )
    end
    
    # Which threads do we expect to have running? Returns an Array of 
    # identifiers for the expected threads.
    def target_thread_identities
      @pool.brokers.map{|b| b.name}
    end
    
    # Given a PollerThread, what is its id for purposes of comparison with
    # the results of #target_thread_identities
    def identify( thread )
      thread.name
    end
    
    private
    
    def destination_pool
      @pool.select{|p| p.destination.broker == broker}
    end
    
  end
end