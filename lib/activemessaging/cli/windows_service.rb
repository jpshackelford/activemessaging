require 'win32/service'
require 'win32/daemon'
require 'reliable-msg'

require 'fileutils'
require 'tempfile'

module ActiveMessaging
  module CLI
    class WindowsService < Win32::Daemon
      
      include ::Win32
      
      SERVICE_NAME        = "ActiveMessaging (#{$0})"
      SERVICE_DESCRIPTION = "ActiveMessaging Poller Daemon" 
      
      RELIABLE_MSG_CONFIG = { 'store' => { 'type' => 'disk' },
                              'drb'   => { 'port' => 8408, 
                                           'acl'  => 'allow 127.0.0.1'}}
                                           
      # Return a structure describing the options.
      def self.parse(args)
        options = OpenStruct.new
        options.argv = args.dup
        options.log_level = ::Logger::INFO
        
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: #{$0} [options] command "
          
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
      
      def self.execute( opts )
        begin
          case opts.command
            when 'install', 'register'
              Service.create(SERVICE_NAME, nil, 
                :display_name       => SERVICE_NAME,
                :description        => SERVICE_DESCRIPTION,
                :binary_path_name   => 'c:\ruby\bin\ruby "' + File.expand_path($0) + '"'
              )                        
              puts "Registered #{SERVICE_NAME} service."
            when 'remove', 'delete'
              if Service.status(SERVICE_NAME).current_state == Service::RUNNING
                Service.stop( SERVICE_NAME )
              end
              Service.delete( SERVICE_NAME )
              puts "Removed service #{SERVICE_NAME}."    
            when 'start'
              Service.start( SERVICE_NAME, nil, opts.argv.join(' ') )
            when 'stop'
              Service.stop( SERVICE_NAME )  
            when 'pause'
              Service.pause( SERVICE_NAME )  
            when 'help'
              ActiveMessaging::CLI::WindowsService.parse(['--help'])
          end        
       rescue Service::Error => e
         puts e
         exit 1
       end         
      end # execute       
                      
      def self.daemonize!
        new.mainloop
      end      
      
      def service_init
        sleep 2  
      end

      def service_main(*args)

        # service_main receives Raw ARGV and needs to parse it. 
        # Note that args here is not the same as ARGV as the whole
        # command-line will be concatenated into a single String.

        class << args
          # normalize args such that ['arg1 arg2 arg3'] = ['arg1','arg2','arg3']
          def normalize; 
            self.join(' ').split      
          end
        end
        
        opts = self.class.parse(args.normalize)
        
        # apply settings from command-line or service dialog  
        logger.level = opts.log_level
       
        # start Reliable Messaging
        reliable_msg.start
        
        # configure ActiveMessaging with a topic which for incoming  
        # configuration messages.
        ActiveMessaging::System.boot_server!
        ActiveMessaging::System.configure do |my|
          my.destination :poller_configuration, '/topic/poller_configuration'
          my.processor   :poller_configuration, ActiveMessaging::ConfigurationProcessor
        end
        
        # Start the ActiveMessaging Poller
        ActiveMessaging::System.start_poller
          
        sleep 5 while state == RUNNING 
      end
    
      def service_stop        
        ActiveMessaging::System.stop_poller
        reliable_msg.stop                        
      end
    
      def service_pause
      end
    
      def service_restart
      end

      private

      def working_directory
        unless defined?( @working_directory )
          profile_path = File.expand_path(ENV['USERPROFILE'])
          my_path = File.join( profile_path, "Application Data", "ActiveMessaging")        
          FileUtils.mkdir_p( my_path )
          Dir.chdir( my_path )
          @working_directory = my_path
        end
        @working_directory
      end
      
      def logger
        unless defined?( @logger )
          f =  "amsvc-pid-#{Process.pid}.log"
          l = ::Logger.new( File.join( working_directory, f) )
          l.formatter = ActiveMessaging::LogFormat.new
          @logger = l
          
          ActiveMessaging::System.logger = l          
        end
        return @logger
      end    
      
      def reliable_msg
        unless defined?( @qm )
          
          RELIABLE_MSG_CONFIG['store']['path'] = working_directory
                    
          config = File.join( working_directory, 'reliable_msg.cfg')          
          
          File.open(config, 'w'){|file| YAML.dump( RELIABLE_MSG_CONFIG, file)}
          
          # ReliableMsg 1.1.0 has a bug in queue-manager.rb line 236
          # drb.merge(@config.drb) if @config.drb should be
          # drb.merge!(@config.drb) if @config.drb
          # as a result the DRB PORT is not read from the configuration file.
          # This hack is a work around.       
          silence_warnings do
            ::ReliableMsg::Config.const_set('DEFAULT_DRB', RELIABLE_MSG_CONFIG['drb'])
            ::ReliableMsg::Client.const_set('DRB_PORT',    RELIABLE_MSG_CONFIG['drb']['port'])            
          end
          
          @qm = ReliableMsg::QueueManager.new( :config => config,
                                               :logger => logger )
        end
        return @qm
      end
      
    end 
  end
end
