module ActiveMessaging
  class PollerThreadPool
    
    def initialize( strategy )
      @strategy = strategy      
      @lock = Mutex.new
      @running = false
      @threads = nil
    end

    # detect changes in the threads which should be running so we can 
    # spin up new ones or delete old ones.
    def update(command, subscription)
      
      unless @running
        LOG.debug "PollerThreadPool has not been started. Ignoring updates."
        return
      end
      
      LOG.debug "PollerThreadPool received new subscription information.\n" +
                "Asking the strategy if we need to add or remove threads."
                
      @lock.synchronize do          
        expected = @strategy.target_thread_identities 
        actual   = @threads.map{|t| @strategy.identify(t)}
        # remove old ones
        (actual - expected).each do |id|
           LOG.debug "Attempting to remove thread id [#{id}]."
           @threads[id].stop
           @threads[id].join
           @threads.delete(t)
           LOG.debug "Successfully removed thread id [#{id}]."
         end
        # create new threads        
        (expected - actual).each do |id|
           LOG.debug "Initializing new thread id [#{id}]"
           @threads.store(id, @strategy.create_thread(id))
           LOG.debug "Starting new thread id [#{id}]"
           @threads[id].start
        end
      end # lock
    end

    # Initializes and executes threads according to the supplied strategy.
    # Neither #start nor #stop are blocking calls. Use #block if you wish
    # to wait for threads to finish executing.
    def start
      @lock.synchronize do            
        if @running
          LOG.debug "Ignoring attempt to start running ThreadPool."  
          return
        end
      
        LOG.debug "Initializing thread pool threads."
        @threads = {}
        @strategy.target_thread_identities.each do |id|
          @threads.store(id, @strategy.create_thread( id ))
        end  
      
        LOG.debug "Attempting to start thread pool threads."
        @threads.values.each{|t| t.start }              
        @running = true
      end      
    end
    
    # Signal the running threads that we are ready to shutdown gracefully.
    # Neither #start nor #stop are blocking calls. If you wish to wait for 
    # threads to finish running, follow up with #block.
    def stop
      LOG.debug "Attempting to stop thread pool threads."
      @lock.synchronize do
        @threads.values.each{|t| t.stop }              
        @running = false
      end
    end
    
    # Block until all threads have finished executing and the pool has been 
    # gracefully shutdown.
    def block
      LOG.debug "Blocking until we've stopped all threads." 
      
      # We have to be careful not to hold a lock such that we can't call #stop
      # but, since we might receive an #update after we've released the lock, 
      # we'll need to keep checking to be sure that no new threads have been 
      # added since we last held the lock.
      loop do
        threads = @lock.synchronize do 
          @threads.values.select{|t| t.alive? } 
        end
        break if threads.size == 0 && @running == false
        threads.each{|t| t.join }
      end
    end
  
    # Use logic similar to that of #block to determine whether we are still
    # running threads in the pool. #stop is a signal 
    def running?
      @running || @lock.synchronize{@threads.values.select{|t|t.alive?}.size>0}
    end
    
  end
end