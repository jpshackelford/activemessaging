module ActiveMessaging
  module Test
    module ReliableMsg
      
      def clear_queues!
        FileUtils.rm_rf( queues_path )  
      end
      
      def queues_path
         ActiveMessaging.lib_path( '..', 'queues')
      end
      
    end
  end
end