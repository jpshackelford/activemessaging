$:.unshift File.dirname(__FILE__)

require 'common_pool'

module ActiveMessaging

  VERSION = "0.5" #maybe this should be higher, but I'll let others judge :)

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

  def ActiveMessaging.configure(options={})
    options.each do |key, val|
      class_variable_set("@@#{key}", val)
    end
  end

  def ActiveMessaging.logger
    @@logger = Logger.new(STDOUT) unless defined?(@@logger)
    @@logger
  end
  
  def ActiveMessaging.root
    @@root
  end
  
  def ActiveMessaging.environment
    @@environment
  end

  # DEPRECATED, so I understand, but I'm using it nicely below.
  def self.load_extensions
    require 'logger'
    require 'activemessaging/support'
    require 'activemessaging/gateway'
    require 'activemessaging/connection_manager'
    require 'activemessaging/adapter'
    require 'activemessaging/message_sender'
    require 'activemessaging/processor'
    require 'activemessaging/filter'
    require 'activemessaging/trace_filter'

    # load all under the adapters dir 
    Dir[File.dirname(__FILE__) + '/activemessaging/adapters/*.rb'].each{|a| 
      begin
        adapter_name = File.basename(a, ".rb")
        require 'activemessaging/adapters/' + adapter_name
        logger.debug "loaded #{adapter_name}"
      rescue RuntimeError, LoadError => e
        logger.debug "ActiveMessaging: adapter #{adapter_name} not loaded: #{ e.message }"
      end
    }
  end

  def self.load_config
    path = File.expand_path("#{A13G.root}/config/messaging.rb")
    begin
      load path
    rescue LoadError
      logger.debug "ActiveMessaging: no '#{path}' file to load"
    rescue
      raise $!, " ActiveMessaging: problems trying to load '#{path}': \n\t#{$!.message}"
    end
  end

  def self.load_processors(first=true)
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

  def self.reload_activemessaging
    # this is resetting the messaging.rb
    ActiveMessaging::Gateway.filters = []
    ActiveMessaging::Gateway.named_destinations = {}
    ActiveMessaging::Gateway.processor_groups = {}
    ActiveMessaging::Gateway.conn_mgr = nil

    # now load the config
    load_config
    load_processors(false)
  end

  def self.load_activemessaging
    load_extensions
    load_config
    load_processors
    A13G::Gateway.create_connection_manager
  end

  def self.start
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

end

#Do not auto-load a13g.  We need to grab configuration from the client code
#ActiveMessaging.load_activemessaging

#Save typing yo
A13G = ActiveMessaging

# reload these on each request - leveraging Dispatcher semantics for consistency
# require 'dispatcher' unless defined?(::Dispatcher)
# 
# # add processors and config to on_prepare if supported (rails 1.2+)
# if ::Dispatcher.respond_to? :to_prepare
#   ::Dispatcher.to_prepare :activemessaging do
#     ActiveMessaging.reload_activemessaging
#   end
# end
