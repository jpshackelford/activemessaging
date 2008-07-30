module ActiveMessaging
  class PollerThread
    
    attr_reader :name, :dispatcher, :interval, :iter, :run_flag
    
    def initialize(options = {})
      @name           = options[:name]
      @iter           = options[:iterator]
      @dispatcher     = options[:dispatcher]
      @interval       = options[:interval]    || 5.0
      @thread = nil
      @run_flag = true
    end
    
    def start
      @thread = Thread.start(self) do |my|
        
        begin
          while( my.run_flag == true ) do
              
              # Next subscription
              LOG.debug "Determine which destination to poll."              
              subscription = my.iter.next_destination
              
              # Grab message
              LOG.debug "Preparing to draw message from #{subscription}."
              m = subscription.destination.receive
              
              # Dispatch
              if m
                LOG.debug "Poller received message."
                begin
                  LOG.debug "Dispatching."              
                  my.dispatcher.dispatch( m )               # get message
                  subscription.destination.received( m )    # commit transaction
                rescue AbortMessageException => error
                  LOG.warn "Exception during dispatch of message #{m}:\n\t" +
                          "#{error}\n\t#{error.backtrace}.\n\t" +
                          "Attempting to return message to the broker."              
                  subscription.destination.unreceive( m )   # roll-back transaction          
                end
              end
              
              # Allow another thread to run.
              sleep my.interval
            end #while
            
          rescue StopProcessingException, Exception => e
            LOG.warn "Poller thread id [#{name}] caught exception:\n\t#{e}\n\t"+
                      e.backtrace.join("\n\t")                      
            stop                                  
          end
          
        end #thread
      end #def
      
      def alive?
        (@thread.alive? if @thread) || false
      end
      
      def join
        (@thread.join if @thread) || false   
      end
      
      def stop
        @run_flag = false
      end
      
      def thread_id
        @thread.object_id
      end
      
    end
  end