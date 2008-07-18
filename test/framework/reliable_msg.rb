module ActiveMessaging
  module Test
    module ReliableMsg
      
      
      # Start the reliable messaging server, wiping out any disk based
      # queues for the sake of testing.
      def start_reliable_messaging
        clear_queues!
        @qm = ::ReliableMsg::QueueManager.new( :logger => ActiveMessaging::System.logger )
        @qm.start 
      end
      
      # Stop the reliable messaging server.
      def stop_reliable_messaging
        @qm.stop unless @qm.nil?
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