# Equivalent to a header guard in C/C++
# Used to prevent the class/module from being loaded more than once
unless defined? ActiveMessaging
  
  $:.unshift File.dirname(__FILE__)
  
  require 'logger'
  require 'yaml'

  require 'rubygems'
  require 'common_pool'
  require 'activesupport'
  require 'rubigen'
  
  require 'activemessaging/support'
  require 'activemessaging/gateway'
  require 'activemessaging/connection_manager'
  require 'activemessaging/adapter'
  require 'activemessaging/message_sender'
  require 'activemessaging/processor'
  require 'activemessaging/filter'
  require 'activemessaging/trace_filter'
  
  module ActiveMessaging
    
    
    VERSION = '0.6.0'

    
    # Used to indicate that the processing for a thread shoud complete
    class StopProcessingException < Interrupt #:nodoc:
    end
    
    # Used to indicate that the processing on a message should cease, 
    # and the message should be returned back to the broker as best it can be
    class AbortMessageException < Exception #:nodoc:
    end
    
    # Used to indicate that the processing on a message should cease, 
    # but no further action is required
    class StopFilterException < Exception #:nodoc:
    end
    
    # methods on the module itself
    class << self
      
      def configure(options={})
        options.each do |key, val|
          class_variable_set("@@#{key}", val)
        end
      end
      
      def logger
        @@logger = Logger.new(STDOUT) unless defined?(@@logger)
        @@logger
      end
           
      def environment
        @@environment
      end
      
      def config_file
        File.expand_path("#{ENV['A13G_HOME']}/config/messaging.rb")
      end

      def load_config          
        if File.exists?( config_file ) 
          logger.debug "ActiveMessaging: loaded configuration #{config_file}."
          load config_file
        else
          logger.debug "ActiveMessaging: no configuration file at #{config_file}."        
        end
      end
      
      def load_adapters
        # load all under the adapters dir 
        Dir[File.dirname(__FILE__) + '/ActiveMessaging/adapters/*.rb'].each{|a| 
          begin
            adapter_name = File.basename(a, ".rb")
            require 'ActiveMessaging/adapters/' + adapter_name
            logger.debug "loaded #{adapter_name}"
          rescue RuntimeError, LoadError => e
            logger.debug "ActiveMessaging: adapter #{adapter_name} not loaded: #{ e.message }"
          end
        }        
      end
      
      def load_processors(first=true)
        #Load the parent processor.rb, then all child processor classes
        begin
          logger.debug "ActiveMessaging: Loading #{A13G.root + '/app/processors/application.rb'}" if first
          load A13G.root + '/app/processors/application.rb'
          Dir[A13G.root + '/app/processors/*.rb'].each do |f|
            unless f.match(/\/application.rb/)
              logger.debug "ActiveMessaging: Loading #{f}" if first
              load f
            end
          end
        rescue MissingSourceFile
        end
      end
      
      
      def reload_ActiveMessaging
        # this is resetting the messaging.rb
        ActiveMessaging::filters = []
        ActiveMessaging::Gateway.named_destinations = {}
        ActiveMessaging::Gateway.processor_groups = {}
        ActiveMessaging::Gateway.conn_mgr = nil
        
        # now load the config
        load_config
        load_processors(false)
        A13G::Gateway.create_connection_manager
      end
      
      
      def load_ActiveMessaging
        logger.debug "loading config"
        load_config
        logger.debug "loading processors"
        load_processors
        logger.debug "creating connection manager"
        A13G::Gateway.create_connection_manager
      end
      
      
      def start
        if ActiveMessaging::Gateway.subscriptions.empty?
          err_msg = <<EOM   

ActiveMessaging Error: No subscriptions.
If you have no processor classes in app/processors, add them using the command:
  script/generate processor DoSomething"

If you have processor classes, make sure they include in the class a call to 'subscribes_to':
  class DoSomethingProcessor < ActiveMessaging::Processor
    subscribes_to :do_something

EOM
          puts err_msg
          logger.error err_msg
          exit
        end
        
        Gateway.start
      end     
      
      
    end # methods on the module     
  end  # module ActiveMessaging
  
  A13G = ActiveMessaging
  A13G.load_adapters
end
