module ActiveMessaging
  module Test
    module Logging
      
      
      def logfile_path
        ActiveMessaging.test_path('test.log')    
      end

      def rm_log
        FileUtils.rm_rf( logfile_path )        
      end
      
      def new_test_logger
        rm_log
        Logger.new( logfile_path )
      end
      
    end
  end
end