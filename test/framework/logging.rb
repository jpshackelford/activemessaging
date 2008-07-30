require 'activesupport'

module ActiveMessaging
  module Test
    
    module Logging
      
      class LogFormat < ::Logger::Formatter        
        silence_warnings do
          Format = "[%s Thread:%8d] %5s -- %s: %s\n"
        end
        
        def call(severity, time, progname, msg)
          display_time = time.strftime("%H:%M:%S.") << "%06d" % time.usec
          Format % [display_time, Thread.current.object_id, severity,  
                    progname, msg2str(msg)]
        end        
      end      
      
      
      private
      
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
        logger = ::Logger.new( logfile_path )
        logger.formatter = LogFormat.new
        return logger
      end
            
      # capture logging statements so we can do assertions against them
      def capture_logging
        begin 
          logger_io = StringIO.new
          logger = ::Logger.new( logger_io )
          logger.formatter = LogFormat.new
          logger.datetime_format = "%H:%M:%S"
          real_logger = ActiveMessaging::System.logger
          ActiveMessaging::System.logger = logger
          yield logger_io
        ensure      
          ActiveMessaging::System.logger = real_logger unless real_logger.nil?
          real_logger.info "logging captured during test:\n" +
                           "#{logger_io.string.chop}"
        end
      end
      
    end
  end
end

# Hack Test::Unit::TestCase so that a message is added to the log file
# separating one test method execution from another.
module Test
  module Unit
    class TestCase
      
      ACTIVE_MESSAGING_PREFIX = File.dirname( __FILE__ ) 
      
      def _log( message )
        ActiveMessaging::LOG.info( message )
      end
      
      # Add a layer of filtering to remove ActiveMessaging Testing Framework
      alias _filter_backtrace filter_backtrace
      
      def filter_backtrace(backtrace, prefix=nil)
        f1 = _filter_backtrace(backtrace, ACTIVE_MESSAGING_PREFIX)
        _filter_backtrace( f1, prefix)
      end
      
      def _log_backtrace( message, backtrace = caller())      
        trace = filter_backtrace(backtrace).join("\n\t")         
        _log( "#{message}\n\t#{trace}")        
      end
      
      def run(result)
        yield(STARTED, name)
        @_result = result
        begin
          # Log that we are about to execute

          # e.g. TestClass - test_name
          pretty_test_name = self.name.chop.split('(').reverse.join(" - ")
          _log( '=' * 80 )
          _log( pretty_test_name)
          _log( '=' * 80 )
          
          # run the test
          setup
          __send__(@method_name)
                   
        rescue AssertionFailedError => e
          add_failure(e.message, e.backtrace)
          _log( "[-] Test Failed.")
          _log_backtrace( e.message, e.backtrace )
        
        rescue Exception => e
          raise if PASSTHROUGH_EXCEPTIONS.include? $!.class
          add_error($!)
          _log( "[x] Error.")
          _log_backtrace( e.message, e.backtrace )   
        
        else
          _log( "[+] Test Passed.")                  
        ensure
          begin
            teardown
          rescue AssertionFailedError => e
            add_failure(e.message, e.backtrace)
          rescue Exception
            raise if PASSTHROUGH_EXCEPTIONS.include? $!.class
            add_error($!)
          end
        end
        result.add_run
        yield(FINISHED, name)
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

