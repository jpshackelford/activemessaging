module ActiveMessaging
  
  # Responsible for selecting the next destination
  # may be better to select from processor_pool
  # than from destination registry since not 
  # all destination registry entries will have 
  # subscribers and we don't want the destination 
  # registry to have to keep track too.
  class BaseIterator
    
    def initialize(&block)
      @pool_initializer = block
      raise ArgumentError, "Iterators must be intialized with a block." if
        @pool_initializer.nil?
      @pool = []
      @lock = Mutex.new
      reload!
    end
    
    # returns a destination    
    def next_destination
      LOG.debug "Attempting to return the next destination."
      @lock.synchronize{ select_next } 
    end

    def update(*args)
      reload!
    end
    
    private
    
    # Override in subclasses with a method which returns a destination to poll. 
    # This is wrapped by #next_destination which provides thread safety, so it
    # it is not necessary to worry about concurrency in your implementation. 
    # Use #pool for read-only access to the pool of destinations from which to
    # choose. 
    def select_next
      raise NotImplementedError.new      
    end
    
    # Re-read the destination pool and update the internal cache removing old
    # destinations and appending new ones. Preserves the order of destinations
    # in the pool. Thread-safe.
    def reload!
      LOG.debug "Attempting to reload #{self}."
      @lock.synchronize do
        expected = @pool_initializer.call 
        actual = @pool
        # remove old destinations
        (actual - expected).each{|d| @pool.delete(d) }
        # append new ones        
        @pool += (expected - actual)
      end
      LOG.debug "Successfully to reloaded #{self}."
    end
    
    # for use in subclasses
    def pool
      @pool.dup
    end

  end
  

  
end