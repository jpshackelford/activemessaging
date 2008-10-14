module ActiveMessaging
  module CLI
    class ReliableMsgCtrl
      
      # Default Port
      DEFAULT_CONFIG = { 'store' => { 'type' => 'disk' },
                         'drb'   => { 'port' => 8408, 
                                      'acl'  => 'allow 127.0.0.1'}}
                                      
      attr_reader :working_directory, :logger
      
      def initialize( working_directory, logger, config = DEFAULT_CONFIG)
        @working_directory = working_directory
        @logger = logger
      end
      
      def start
        reliable_msg.start
      end
      
      def stop
        reliable_msg.stop
      end          
      
      def reliable_msg
        unless defined?( @qm )

          FileUtils.mkdir_p( working_directory )          
          config = File.join( working_directory, 'reliable_msg.cfg')          
          
          DEFAULT_CONFIG['store']['path'] = working_directory
          
          File.open(config, 'w'){|file| YAML.dump( DEFAULT_CONFIG, file)}
          
          # ReliableMsg 1.1.0 has a bug in queue-manager.rb line 236
          # drb.merge(@config.drb) if @config.drb should be
          # drb.merge!(@config.drb) if @config.drb
          # as a result the DRB PORT is not read from the configuration file.
          # This hack is a work around.       
          silence_warnings do
            ::ReliableMsg::Config.const_set('DEFAULT_DRB', DEFAULT_CONFIG['drb'])
            ::ReliableMsg::Client.const_set('DRB_PORT',    DEFAULT_CONFIG['drb']['port'])            
          end
          
          @qm = ReliableMsg::QueueManager.new( :config => config,
                                               :logger => logger )
        end
        return @qm
      end          
                                      
    end # class
  end
end
