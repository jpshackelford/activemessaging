module ActiveMessaging
  
  # Determine how we are going to divide the processor pool across threads. 
  class BasePollingStrategy

     def initialize( subscription_registry )
      @subscription_registry = subscription_registry
      @thread_pool = nil
    end
    
    # Return an instance of the the thread pool for the poller to use.
    # This default implementation returns an PollerThreadPool which may 
    # be configured to observe changes in the SubscriptionRegistry with 
    # which the BasePollingStrategy is initialized. The returned 
    # PollerThreadPool must respond to #start, #stop, #block and #running?.
    # If the PollerThreadPool has an #update method which can be called with
    # two parameters, we will register it as a listener of the 
    # SubscriptionRegistry.
    def thread_pool
      unless defined?( @thread_pool ) && @thread_pool != nil
        @thread_pool = PollerThreadPool.new( self )
        @subscription_registry.add_observer( @thread_pool ) if 
          is_listener?( @thread_pool )
      end
      @thread_pool
    end

    # Which threads do we expect to have running? Returns an Array of 
    # identifiers for the expected threads expected to be equal to the names
    # given threads and available via PollerThread#name.
    def target_thread_identities
      raise NotImplementedError, "Implement in subsclasses."
    end
    
    # Create new PollerThread for a given target thread id. The id supplied 
    # should be used as the value for PollerThread#name.
    def create_thread( id )
      raise NotImplementedError, "Implement in subsclasses."
    end
        
    def to_s
      self.class.name  
    end
    
    private
    # If the object has an #update method which can be called with two
    # arguments, consider it a listener. 
    def is_listener?( object )
      return object.respond_to?( :update ) && 
          
          # has two required arguments
          object.method( :update ).arity == 2 ||
          
          # has an optional argument (-1), one required and one optional (-2)
          # or two required and one optional (-3). Since optional arguments
          # can take take 0 to infinite number of actual parameters passed in, 
          # any of these will take a method call which passes two parameters.  
          (-3..-1).include?( object.method( :update ).arity )              
    end
    
  end
  
  
end
