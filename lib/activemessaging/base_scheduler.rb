module ActiveMessaging
  
  # Responsible for selecting the next destination
  # may be better to select from processor_pool
  # than from destination registry since not 
  # all destination registry entries will have 
  # subscribers and we don't want the destination 
  # registry to have to keep track too.
  class BaseScheduler
    
    def initialize( options = {})
      @pool_initializer = options[:pool_initializer]
      @expiry_policy    = options[:expiry_policy] 
      @pool = []
      @frozen_pool = nil
      @guard = Mutex.new
      reload!
    end
    
    # returns a destination    
    def next_destination
      @guard.synchronize do
        reload! if cache_expired?
        schedule 
      end  
    end
    
    private
    
    # Override in subclasses with a method which returns a destination to poll. 
    # This is wrapped by #next_destination which provides thread safety, so it
    # it is not necessary to worry about concurrency in your implementation. 
    # Use #pool for read-only access to the pool of destinations from which to
    # choose. 
    def schedule
      raise NotImplementedError.new      
    end
    
    # Re-read the destination pool and update the internal cache removing old
    # destinations and appending new ones. Preserves the order of destinations
    # in the pool. Thread-safe.
    def reload!
      @guard.synchronize do
        expected = @pool_initializer.call 
        actual = @pool
        # remove old destinations
         (actual - expected).each{|d| @pool.delete(d) }
        # append new ones        
        @pool += (expected - actual)
        @frozen_pool = @pool.dup.freeze
        @expiry_policy.reset(:count => pool.size)
      end
    end
    
    # Read-only access to the cache of destinations from which to schedule.
    def pool
      @frozen_pool
    end
    
    def cache_expired?
      @expiry_policy.expired?
    end
    
  end
  
  class CallCountExpiryPolicy
    
    def initialize(options = {})
      reset( options )
    end
    
    def expired?
      @count += 1
      return @count > @max  
    end
    
    def reset(options = {})
      @max = options[:count] || 1
      @count = 0
    end
    
  end
  
  
  class TimeExpiryPolicy
    
    def initialize(options = {})
      reset( options )
    end
    
    def expired?
      return Time.now > @max
    end
    
    def reset(options = {})
      @max = Time.now + ( options[:seconds] || 60) # a minute  
    end
    
  end
  
end