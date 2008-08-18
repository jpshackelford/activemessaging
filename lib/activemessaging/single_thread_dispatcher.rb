module ActiveMessaging
  
  # This follows the strategy implemented in the previous version of 
  # ActiveMessaging: only one message is dispatched at time regardless of the
  # number of polling threads. Consider the alternative ThreadPoolDispatcher.
  class SingleThreadDispatcher
    
    def initialize( subscription_registry )
      @lock = Mutex.new
      @subscription_registry = subscription_registry    
    end
    
    def dispatch( message )
      # Ordinarily we follow the rule that we don't ever hold more than
      # one lock at time so that we can avoid deadlocks, but since threads
      # calling the dispatcher will never hold other locks, we can guarantee
      # that the dispatcher will always be the first lock held. As long as we
      # never hold more than one lock while dispatching, we should avoid 
      # trouble.  
      @lock.synchronize do
        LOG.info  "Dispatching message: #{message.headers[:id]}"
        LOG.debug "Dispatching message:\n\n#{message}\n\n"
        
        processors = @subscription_registry.processors_for( message )
        LOG.warn "No processors for #{message}." if processors.empty?
        
        processors.each do |p|
          LOG.info "Processing message: #{message.headers[:id]} with #{p}."
          LOG.debug "Processing message:\n\n#{message}\n\n"
          p.process!( message )
        end
        
      end
    end
    
    
    
  end
end