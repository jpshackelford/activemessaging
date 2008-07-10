module ActiveMessaging
  class ThreadPool
    
    def initialize( *options )
      @strategy = options[:strategy]      
      @threads = {}
      
      # initialize threads
      @strategy.target_thread_identities.each do |id|
        @threads.store(id, @strategy.create_thread( id ))
      end
      
      # detect changes in the threads which should be running so we can 
      # spin up new ones or delete old ones.
      @change_detection_thread = Thread.start do
        # run - loop
        expected = @strategy.target_thread_identities 
        actual   = @threads.map{|t| @strategy.identify(t)}
        # remove old ones
         (actual - expected).each do |id| 
          @threads[id].stop
          @threads[id].join
          @threads.delete(t)
        end
        # create new threads        
         (expected - actual).each do |id| 
          @threads.store(id,@strategy.create_thread(id))
        end
      end
      
      
    end
    
    def start
    end
    
    def stop
    end
    
  end
end