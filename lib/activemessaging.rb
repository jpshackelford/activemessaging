unless defined? ActiveMessaging
  
  $:.unshift File.dirname(__FILE__)
  
  # threading library
  require 'thread'
  begin
    require 'fastthread'
  rescue LoadError
  end
  
  # stdlib
  require 'logger'
  require 'monitor'
  require 'optparse'
  require 'ostruct'
  require 'yaml'
    
  # rubygems
  require 'rubygems'
  require 'common_pool'
  require 'activesupport'
  require 'rubigen'
  
  # ActiveMessaging
  require 'activemessaging/message_sender'
  
  require 'activemessaging/base_iterator'
  require 'activemessaging/base_message'
  require 'activemessaging/base_polling_strategy'
  require 'activemessaging/base_processor'
  require 'activemessaging/base_registry'
  require 'activemessaging/broker'
  require 'activemessaging/broker_registry'
  require 'activemessaging/configuration_processor'
  require 'activemessaging/core_ext'  
  require 'activemessaging/custom_class_registry'
  require 'activemessaging/destination_registry'
  require 'activemessaging/gateway'
  require 'activemessaging/log_format'
  require 'activemessaging/poller'
  require 'activemessaging/poller_thread'
  require 'activemessaging/poller_thread_pool'
  require 'activemessaging/processor_registry'
  require 'activemessaging/round_robin_iterator'
  require 'activemessaging/single_thread_dispatcher'
  require 'activemessaging/subscription_registry'
  require 'activemessaging/system_kernel'
  require 'activemessaging/thread_per_broker_strategy'
  
  require 'activemessaging/cli/windows_service'
  
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
    
    # Raise when transactional integrity is compromised. Probably a programming
    # error if we ever see one of these. 
    class TransactionError < Exception
    end
    
    # Attempted to perform an operation on a destination which doesn't exist.
    class NoDestinationError < Exception    
    end
    
    # Create ActiveMessaging.reset! method.
    class << self
      # Restart all of ActiveMessaging stopping the running poller (if any) 
      # and resetting all registries. The only thing that lives through the
      # reset is the logger.
      def reset!
        Kernel.silence_warnings do
          if defined?( System )
            previous_logger = System.logger
            System.reset!
            ActiveMessaging.const_set(:System, nil)
          end          
          ActiveMessaging.const_set(:System, SystemKernel.new)
          ActiveMessaging::System.logger = previous_logger if 
          defined?( previous_logger ) && previous_logger != nil
        end
      end
    end
    
    # boot up!
    reset!
  end
end # defined?