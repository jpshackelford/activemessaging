require File.dirname(__FILE__) + '/test_helper'

require 'mock_processor'
require 'null_logger'

class IntegrationTest < Test::Unit::TestCase 
  
  def setup
    ActiveMessaging::System.logger = NullLogger.new
  end
  
  def test_poller
    
    # mock up a processor class
    mock_processor_class = MockProcessor.new.
      expect("test message", {}, count = 1)
    
    # set up a broker, destination, and processor
    ActiveMessaging::System.configure do |my|
      my.broker      :reliable_msg => {}
      my.destination :hello_world, '/queue/helloWorld', {}, :reliable_msg
      my.processor   :hello_world, mock_processor_class, headers={}
    end
       
    # start the poller
    t = Thread.start{ ActiveMessaging::System.poller_start }
    
    # send a message
    ActiveMessaging::System.gateway.
      publish :hello_world, "test_message", headers = {}
    
    # wait for a reasonable length of time and 
    # verify that the message was processed.
    sleep 2.0    
    mock_processor_class.verify!
    
    # stop the poller
    ActiveMessaging::System.poller_stop
    t.join
  end
    
end

