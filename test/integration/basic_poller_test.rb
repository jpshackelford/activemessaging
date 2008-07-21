require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'mocks/mock_processor'

begin
  require 'reliable-msg'
rescue LoadError
else
  
  
  
  # Tests poller for one broker, one destination, and one message using
  # ReliableMsg broker.
  class BasicPollerTest < Test::Unit::TestCase 
    
    include ActiveMessaging::Test::ReliableMsg
    include ActiveMessaging::Test::PollerControl
    
    def setup
      start_reliable_messaging
    end
    
    def teardown
      stop_reliable_messaging
    end
    
    # Simplest end-to-end test.
    def test_single_broker_destination_and_message
      
      # mock up a processor class
      mock_processor_class = MockProcessor.new.expect(1, "test message")
      
      # set up a broker, destination, and processor
      ActiveMessaging::System.boot_server!
      ActiveMessaging::System.configure do |my|
        my.broker      :reliable_msg, {}
        my.destination :hello_world, '/queue/helloWorld', {}, :reliable_msg
        my.processor   :hello_world, mock_processor_class, headers={}
      end
      
      start_poller
      
      # send a message
      ActiveMessaging::System.gateway.publish :hello_world, "test message"
      
      # Wait for a reasonable length of time for message 
      # to arrive and poller to pick it up. Adjust this value
      # if test appears to fail intermittently or without cause.
      sleep 0.2
      
      stop_poller
      
      # verify that the message was processed
      verify_mock mock_processor_class
    end
    
  end
  
end
