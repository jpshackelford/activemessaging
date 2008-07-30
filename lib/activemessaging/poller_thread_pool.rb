module ActiveMessaging
  class PollerThreadPool
    
    def initialize( strategy )
      @strategy = strategy      
      @pool_lock = Mutex.new
      @blocking_lock = Mutex.new
      @blocking_cv = ConditionVariable.new
      @running = false
      @received_stop = false
      @threads = nil
    end
    
    # detect changes in the threads which should be running so we can 
    # spin up new ones or delete old ones.
    def update(command, subscription)
      
      unless @running      
        LOG.debug "[P] PollerThreadPool has not been started. Ignoring updates."
        # We should be able to do this safely since when we start the poller
        # we should look for subscription info immediately.
      end
      
      LOG.debug "[P] PollerThreadPool received new subscription information." 
      LOG.debug "[P] Asking the strategy if we need to add or remove threads."
      
      @pool_lock.synchronize do          
        expected = @strategy.target_thread_identities 
        actual   = @threads.map{|t| t.name}
        # remove old ones
        (actual - expected).each do |id|
          LOG.debug "[P] Attempting to remove thread id [#{id}]."
            t = @threads.find{|t| t.name == id}
            t.stop
            t.join
            @threads.delete(t)
          LOG.debug "[P] Successfully removed thread id [#{id}]."
        end
        # create new threads        
        (expected - actual).each do |id|
          LOG.debug "[P] Initializing new thread id [#{id}]"
          t = @strategy.create_thread(id)
          @threads << t
          LOG.debug "[P] Starting new thread id [#{id}]"
          t.start
        end
      end # lock
    end
    
    # Initializes and executes threads according to the supplied strategy.
    # Neither #start nor #stop are blocking calls. Use #block if you wish
    # to wait for threads to finish executing.
    def start
      @pool_lock.synchronize do                
        
        if @running
          LOG.debug "[P] Ignoring attempt to start running ThreadPool."  
          return
        end               
        
        @received_stop = false # Reset otherwise previous stop signal 
        # will hang around.        
        
        unless @received_stop # respond quickly to immediate stops
          LOG.debug "[P] Initializing thread pool threads."
          @threads = []
          @strategy.target_thread_identities.each do |id|
            @threads << @strategy.create_thread( id )
          end          
        end
        
        unless @received_stop # respond quickly to immediate stops
          LOG.debug "[P] Starting thread pool threads."
          @threads.each{|t| t.start }                       
          @running = true 
        end        
        
      end      
    end
    
    # Signal the running threads that we are ready to shutdown gracefully.
    # Neither #start nor #stop are blocking calls. If you wish to wait for 
    # threads to finish running, follow up with #block.
    def stop
      LOG.debug "[P] Attempting to stop thread pool threads."
      @received_stop = true # Propagate the stop signal ASAP, particularly
      # important if we are running #start on another
      # thread.
      
      # Send #stop signal to each thread. This is not brute force given since
      # PollerThread which sets a flag and completes safely. 
      @pool_lock.synchronize do
        @threads.each{|t| t.stop }
        @running = false
      end
      
      # Wake up any blocking threads.
      @blocking_cv.signal
    end
    
    # Block until all threads have finished executing and the pool has been 
    # gracefully shutdown. May be called after #start or #stop.
    def block
      LOG.debug "[P] Blocking thread #{Thread.current.object_id} " +
                "until we receive a stop signal." 
      
      # Put the current thread to sleep until we receive a stop signal
      # Unless we've received it already.
      @blocking_lock.synchronize do
        @blocking_cv.wait( @blocking_lock ) unless @received_stop        
      end
      
      # We have to be careful not to hold a lock such that we can't call #stop
      # or #update but, since we might receive an #update after we've released
      # the lock, we'll need to keep checking to be sure that no new threads 
      # have been added since we last held the lock.      
      
      loop do        
        LOG.debug "[P] Waiting for all poller threads to finish up."
        threads = running_threads
        break if threads.size == 0 && @running == false
        threads.each do |t| 
          t.join
          LOG.debug "[P] Thread #{t.thread_id} stopped."
        end
      end
      
      LOG.debug "[P] PollerThreadPool has shutdown gracefully. " + 
                "Thread #{Thread.current.object_id} may proceed."
    end
    
    # Use logic similar to that of #block to determine whether we are still
    # running threads in the pool. #stop is a signal 
    def running?
      @running || running_threads.size > 0
    end
    
    # List running threads. Thread-safe.
    def running_threads
      @pool_lock.synchronize do 
        @threads.select{|t| t.alive? } 
      end      
    end
        
    def to_s
      self.class.name  
    end
    
  end
end