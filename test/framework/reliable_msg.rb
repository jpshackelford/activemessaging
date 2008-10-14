module ActiveMessaging
  module Test
    module ReliableMsg
            
      # Start the reliable messaging server, wiping out any disk based
      # queues for the sake of testing.
      def start_reliable_messaging
        clear_queues!
        unless defined?( @r )
          @r = ::ActiveMessaging::CLI::ReliableMsgCtrl.new( 
                          queues_path,
                          ActiveMessaging::System.logger )                        
        end
        @r.start 
      end
      
      # Stop the reliable messaging server.
      def stop_reliable_messaging
        @r.stop unless @r.nil?
      end

      def clear_queues!
        FileUtils.rm_rf( queues_path )  
      end
      
      def queues_path
        ActiveMessaging.lib_path( '..', 'queues')
      end      
      
    end
  end
end