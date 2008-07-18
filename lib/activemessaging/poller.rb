module ActiveMessaging
  
  class Poller
 
    def initialize( polling_strategy )
      @polling_strategy = polling_strategy      
      @thread_pool = polling_strategy.thread_pool 
    end
    
    # Begin polling
    def start
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

  end
end
