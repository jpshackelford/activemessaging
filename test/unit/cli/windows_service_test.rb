require File.expand_path( File.dirname(__FILE__) + '/../../test_helper' )

if RUBY_PLATFORM =~ /djgpp|(cyg|ms|bcc)win|mingw/
    
  class WindowsServiceTest < Test::Unit::TestCase  
    
   TEST_SVC_NAME   = 'win32-svc-test'
   TEST_SVC_REGEXP = Regexp.new( TEST_SVC_NAME.gsub('-','\-'))
   TEST_LOG = ActiveMessaging.test_path( TEST_SVC_NAME + '.log')
   
    def setup
      @svc_class = ActiveMessaging::CLI::WindowsService            
      instrument_class @svc_class      
    end
    
    def teardown 
      # remove any services we may have created
      Win32::Service.services do |svc|        
        if TEST_SVC_REGEXP =~ svc.service_name
          if svc.current_state == 'running'          
            Win32::Service.stop( svc.service_name )
          end
          Win32::Service.delete( svc.service_name )
        end
      end      
      # clear log
      retrying_on_error(5, "Failed to delete #{TEST_LOG}", 1) do
        FileUtils.rm TEST_LOG if File.exist?( TEST_LOG )
      end
    end

    def test_register
      stdout, stderr, exception = run_cmd('register')
      raise exception unless exception.nil? || exception.kind_of?( SystemExit )
      
      assert_match /Registered/, stdout, "Expected command line output missing."
    
      assert_equal true, Win32::Service.exists?( @svc_class.service_name ),
        "Failed to register the service."
        
      service_info = Win32::Service.config_info( @svc_class.service_name )
      
      assert File.exists?( @svc_class.script_file ),
        "Fixture does not point the appropriate script file."
        
      assert_equal @svc_class.executable , service_info[:binary_path_name],
        "Service registered with bad binary file name."
    end
    
    def test_service_start
      
      # register the service
      run_cmd 'register'
      
      # start it
      stdout, stderr, exception = run_cmd 'start',
                                          '--log', 'info', 
                                          '--dir', '"' + queues_dir  + '"',
                                          '--logfile', '"' + TEST_LOG + '"'
                                          
      raise exception unless exception.nil? || exception.kind_of?( SystemExit )
      
      assert_match /Started/, stdout, "Expected command line output missing."            
      assert_match /Preparing server/, service_log
      assert_match /Enabling hot configuration on the server/, service_log
    end
    
    private
    
    def queues_dir
      File.expand_path( File.join( ActiveMessaging::TEST_DIR, '..', 'queues'))
    end
    
    def retrying_on_error( attempts, fail_message, retry_interval = 0.1 ) 
      begin
        return yield if block_given?
      rescue Exception
        sleep retry_interval
        attempts -= 1   
        retry if attempts > 0
        flunk fail_message
      end  
    end
    
    def service_log
      retrying_on_error ( 3, "Could not open the log at: #{TEST_LOG}") do
        File.open( TEST_LOG, 'r'){|f| f.read}
      end
    end
    
    # Execute cmd and return stdout, stderr, and any exceptions
    def run_cmd( *args )
      begin
        stdout_orig = $stdout
        stderr_orig = $stderr
        stdout = StringIO.new
        stderr = StringIO.new
        $stdout = stdout
        $stderr = stderr
        opts = @svc_class.parse( args )
        @svc_class.execute( opts )
        return [ stdout.string, stderr.string, nil ]
      rescue Exception => e
        return [ stdout.string, stderr.string, e ]
      ensure
        $stdout = stdout_orig
        $stderr = stderr_orig        
      end
    end
    
    # Instrument the class to allow us to capture output
    # and to be sure we don't clobber a properly installed
    # production service.
    def instrument_class( service_class )
      class << service_class
        def script_file
          File.expand_path( File.join( ActiveMessaging::TEST_DIR, '..', 'bin', 'amsvc'))
        end
        def executable
          'ruby "' + script_file + '"'
        end        
        def cmd_name
          WindowsServiceTest::TEST_SVC_NAME
        end
      end # class
    end
    
  end  # class
else
  print "\nSkipping Windows tests.\n"
end # if defined
