require 'win32/service'
require 'win32/daemon'
require 'reliable-msg'

require 'fileutils'
require 'tempfile'
require 'shellwords'

module ActiveMessaging
  module CLI
    class WindowsService < Win32::Daemon
      
      SERVICE_DESCRIPTION = "ActiveMessaging Poller Daemon" 
      
      RELIABLE_MSG_CONFIG = { 'store' => { 'type' => 'disk' },
                              'drb'   => { 'port' => 8408, 
                                           'acl'  => 'allow 127.0.0.1'}}
      # class methods
      class << self
              
        # Return a structure describing the options.     
        def parse(args)
          options = OpenStruct.new
          options.argv = args.dup
          # defaults
          options.log_level = ::Logger::INFO
          options.dir       = working_directory 
          options.logfile   = logfile
          
          opts = OptionParser.new do |opts|            
            opts.banner = "Usage: #{cmd_name} [options] command "
            
            opts.separator ""
            opts.separator "Commands:"          
            opts.separator ""
            
            opts.separator "install            register the service with windows "
            opts.separator "remove             remove the service from the windows registry"
            opts.separator "start              start the service"
            opts.separator "stop               stop the service"
            opts.separator "help               display this message"
                      
            opts.separator ""
            opts.separator "Common options:"
                      
            opts.on("--log LEVEL", [:debug, :info, :warn],
                    "Select logging level (debug, info, warn)") do |t|
              begin              
                options.log_level = ::Logger.const_get( t.to_s.upcase )
              rescue NameError, TypeError
                # ignore the error and use the default above. 
              end
            end
  
            opts.on('-d', '--dir DIRECTORY', "Specify the working directory") do |dir|
              options.dir = dir
            end
            
            opts.on('--logfile FILE_PATH', 'Specify log file location') do |logfile|
              options.logfile = logfile
            end
            
            opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit
            end
            
            opts.on_tail("--version", "Show version") do
              puts "ActiveMessaging #{ActiveMessaging::VERSION}"
              exit
            end
  
          end
          
          opts.parse!(args)
          options.command = (args.shift || 'help').downcase
          return options
        end  # parse      
        
        def execute( opts )
          begin
            case opts.command
            when 'install', 'register'
                Win32::Service.create( service_name , nil, 
                  :display_name       => service_name,
                  :description        => SERVICE_DESCRIPTION,
                  :binary_path_name   => executable
                )                        
                puts "Registered #{service_name} service."
              when 'remove', 'delete'
                if Win32::Service.status(service_name).current_state == 
                    Win32::Service::RUNNING
                  Win32::Service.stop( service_name )
                end
                Win32::Service.delete( service_name )
                puts "Removed service #{service_name}."    
              when 'start'
                Win32::Service.start( service_name, nil, opts.argv.join(' ') )
                puts "Started #{service_name} service."
                puts "Working directory is: #{opts.dir}"
              when 'stop'
                Win32::Service.stop( service_name )
                puts "Stopped #{service_name} service."
              when 'help'
                ActiveMessaging::CLI::WindowsService.parse(['--help'])
            end        
         rescue ::Win32::Service::Error => e
           puts e
           exit 1
         end         
        end # execute       
                        
        def daemonize!
          new.mainloop
        end      
        
        def cmd_name
          File.basename( $PROGRAM_NAME )                
        end
  
        def service_name
          "ActiveMessaging (#{cmd_name})"
        end
        
        def executable
          'ruby "' + $PROGRAM_NAME + '"' 
        end 
        
        def working_directory
          profile_path = File.expand_path(ENV['USERPROFILE'])
          File.join( profile_path, "Application Data", "ActiveMessaging")                  
        end
        
        def logfile          
          File.join( working_directory, "#{cmd_name}-pid-#{Process.pid}.log")
        end
        
      end # class methods
      
      def service_init
        sleep 2  
      end

      def service_main(*args)
        
        # service_main receives Raw ARGV and needs to parse it. 
        # Note that args here is not the same as ARGV as the whole
        # command-line will be concatenated into a single String.
        class << args
          # normalize args such that ['arg1 arg2 arg3'] = ['arg1','arg2','arg3']
          # and deal with quoted spaces properly.
          def normalize; 
            Shellwords.shellwords( self.join(' '))      
          end
        end
        
        opts = self.class.parse(args.normalize)
        
        # apply settings from command-line or service dialog  
        init_dir( opts.dir )
       
        logging_crashes( File.join( opts.dir, 'crash.log')) do
        
          start_logger( opts.logfile, opts.log_level )
  
          # start Reliable Messaging
          reliable_msg.start
          
          # configure ActiveMessaging with a topic which for incoming  
          # configuration messages.        
          ActiveMessaging::System.boot_server!
          ActiveMessaging::System.enable_hot_configure!
          
          # Start the ActiveMessaging Poller
          ActiveMessaging::System.start_poller 
          
          # Exit message.
          case state 
            when RUNNING 
              logger.warn "The poller appears to have stopped before the " \
                          "Windows service instructed it to do so."
            when STOP_PENDING, STOPPED
              logger.info "Windows service stopped normally."
          end
          
        end # logging_crashes
      end
    
      def service_stop
        ignoring_errors{ ActiveMessaging::System.stop_poller }
        ignoring_errors{ reliable_msg.stop }  
      end
    
      def service_restart
        service_stop
        service_start
      end

      private
      
      attr_reader :working_directory, :logger
      
      def init_dir( dir )
        FileUtils.mkdir_p( dir )
        Dir.chdir( dir )
        @working_directory = dir
      end

      def start_logger( logfile, loglevel )
        @logger = ::Logger.new( logfile )
        @logger.formatter = ActiveMessaging::LogFormat.new
        @logger.level = loglevel
        @logger.warn "Re-initialized Logger."
        ActiveMessaging::System.logger = @logger        
      end
            
      def reliable_msg
        unless defined?( @qm )          
          @qm = ReliableMsgCtrl.new( working_directory, logger )
        end
        return @qm
      end

      def ignoring_errors
        begin
          yield if block_given?
        rescue Exception
          # ignore
        end        
      end # def
    
      def logging_crashes( file )
        begin
          FileUtils.rm_f( file )
          yield if block_given?
        rescue Exception => e                    
          crash_log = Logger.new( file )
          crash_log.fatal "A fatal error occurred.\n#{e}\n\t#{e.backtrace.join("\n\t\t")}"          
        end
      end
      
    end 
  end
end
