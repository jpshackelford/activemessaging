require File.dirname(__FILE__) + '/test_helper'


class PollerTest < Test::Unit::TestCase
  
  def test_receive
    ActiveMessaging::Gateway.destination :hello_world, '/queue/helloWorld'
    ActiveMessaging::Gateway.publish :hello_world, "test_publish body", self.class, headers={}, timeout=10
    msg = ActiveMessaging::Gateway.receive :hello_world, self.class, headers={}, timeout=10
    assert_not_nil ActiveMessaging::Gateway.connection.find_message('/queue/helloWorld', "test_publish body")
  end
  
  
end