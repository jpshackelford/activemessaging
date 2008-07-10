module ActiveMessaging
  
  class Poller
 
    def initialize( polling_strategy )
      @polling_strategy = polling_strategy
    end
    
    # Begin polling
    def start
      initialize_thread_pool if @thread_pool.nil? 
      Signal.trap('TERM', 'EXIT'){ stop }
      @thread_pool.start
    end
    
    # Stop polling
    def stop
      @thread_pool.stop
    end
    
    def running?
      @thread_pool.running?      
    end
    
    private
    
    def initialize_thread_pool
      @thread_pool = ThreadPool.new( @polling_strategy )
    end

  end
end
