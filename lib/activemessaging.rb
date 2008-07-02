$:.unshift File.dirname(__FILE__)

require 'logger'
require 'yaml'

require 'rubygems'
require 'common_pool'
require 'activesupport'
require 'rubigen'

require 'activemessaging/hash'
require 'activemessaging/support'
require 'activemessaging/null_logger'
require 'activemessaging/object_bank'
require 'activemessaging/configuration_dsl'
require 'activemessaging/system_globals'
require 'activemessaging/initializer'

require 'activemessaging/poller'
require 'activemessaging/destination_registry'
require 'activemessaging/processor_pool'

require 'activemessaging/gateway'
require 'activemessaging/connection_manager'
require 'activemessaging/adapter'
require 'activemessaging/message_sender'
require 'activemessaging/processor'
require 'activemessaging/filter'
require 'activemessaging/trace_filter'

module ActiveMessaging
  
  VERSION = '0.7.0'
  
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
  
  # Raised when a configuration file contains an error. #:nodoc:
  class BadConfigurationException < Exception      
  end
  
end
