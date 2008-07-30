module ActiveMessaging
  module Test
    module PollerControl
      
      # start the poller
      def start_poller
        @poller_thread = Thread.start do
          begin        
            ActiveMessaging::System.start_poller
          rescue Exception => exception
            Thread.current[:exception] = exception
            ActiveMessaging::LOG.error "Error in test script:\n\t#{exception}."         
          end
        end
        ActiveMessaging::LOG.info "Starting poller for testing in thread: " +
                                  "#{@poller_thread.object_id}"
      end
      
      # stop the poller raising any exceptions generated by the poller.
      def stop_poller              
        ActiveMessaging::System.stop_poller
        if @poller_thread
          @poller_thread.join
          ActiveMessaging::LOG.info "Test poller thread retired: " +
                                    "#{@poller_thread.object_id}"          
          if e = @poller_thread[:exception]
            raise e unless e.nil?
          end        
        end
      end
      
      # Shortcut for ActiveMessaging::System.gateway.publish
      def publish(*args)
        ActiveMessaging::System.gateway.publish(*args)
      end
      
      # Shortcut for ActiveMessaging::System.registry_entry
      def registry_entry( *args )
        ActiveMessaging::System.registry_entry( *args )
      end
      
      
    end
  end
end