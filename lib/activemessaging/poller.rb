module ActiveMessaging
  
  class Poller
 
    def initialize( polling_strategy, subscription_registry )
      @polling_strategy = polling_strategy
      @subscription_registry = subscription_registry
      @thread_pool = PollerThreadPool.new( polling_strategy )
    end
    
    # Begin polling
    def start
      initialize_thread_pool if @thread_pool.nil? 
      Signal.trap('TERM', 'EXIT'){ stop }
      LOG.debug "Starting poller."
      @thread_pool.start
      @thread_pool.block
    end
    
    # Stop polling
    def stop
      LOG.debug "Stopping poller."
      @thread_pool.stop
    end
    
    def running?
      @thread_pool.running?      
    end
    
    private
    
    def initialize_thread_pool
      @thread_pool = PollerThreadPool.new( @polling_strategy, @subscription_registry )
      @subscription_registry.add_observer( @thread_pool )
    end

  end
end
