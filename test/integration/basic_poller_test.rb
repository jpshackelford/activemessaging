require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'framework/reliable_msg'
require 'mocks/mock_processor'

begin
  require 'reliable-msg'
rescue LoadError
else
  
  # Tests poller for one broker, one destination, and one message using
  # ReliableMsg broker.
  class BasicPollerTest < Test::Unit::TestCase 
        
    include ActiveMessaging::Test::ReliableMsg
    
    def setup
      # ReliableMsg broker uses a disk based queue which needs
      # to be wiped out before we run any tests.
      clear_queues!
      # Start up the ReliableMsg adapter
      @qm = ReliableMsg::QueueManager.new( :logger => ActiveMessaging::System.logger )
      @qm.start    
    end
        
    def teardown
      @qm.stop unless @qm.nil?
    end
    
    # Simplest end-to-end test.
    def test_single_broker_destination_and_message
      
      # mock up a processor class
      mock_processor_class = MockProcessor.new.
      expect("test message", {}, count = 1)
      
      # set up a broker, destination, and processor
      ActiveMessaging::System.boot_server!
      ActiveMessaging::System.configure do |my|
        my.broker      :reliable_msg, {}
        my.destination :hello_world, '/queue/helloWorld', {}, :reliable_msg
        my.processor   :hello_world, mock_processor_class, headers={}
      end
      
      # start the poller
      t = Thread.start do
        begin        
          ActiveMessaging::System.start_poller
        rescue Exception => exception
          Thread.current[:exception] = exception
        end
      end
      
      # send a message
      ActiveMessaging::System.gateway.
        publish :hello_world, "test message", headers = {}
      
      # wait for a reasonable length of time 
      sleep 2   

      # stop the poller      
      ActiveMessaging::System.stop_poller
      t.join
      
      if e = t[:exception]
        puts e, e.backtrace.join("\n\t") if e
        raise e
      end
      
      # verify that the message was processed
      mock_processor_class.verify!
    end
    
  end
  
end