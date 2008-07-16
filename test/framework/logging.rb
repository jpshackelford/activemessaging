module ActiveMessaging
  module Test
    module Logging
      
      # Location where test log is stored.
      def logfile_path
        ActiveMessaging.test_path('test.log')    
      end
      
      # Remove the log file.
      def rm_log
        FileUtils.rm_rf( logfile_path )        
      end

      # Remove the old log file and create a new log file.
      def new_test_logger
        rm_log
        Logger.new( logfile_path )
      end
      
    end
  end
end

# Hack Test::Unit::TestCase so that a message is added to the log file
# seperating one test method execution from another.
module Test
  module Unit
    class TestCase
      alias _run run
      def run( *args, &block )
        begin
          ActiveMessaging::System.logger.info("------- #{self.name} ----------") 
        rescue Exception
        end
        _run( *args, &block )
      end
    end
  end
end


# capture warning messages, particularly those issued by UUID.
module Kernel
  def warn( message )
    ActiveMessaging::System.logger.warn( message )
  end
end

