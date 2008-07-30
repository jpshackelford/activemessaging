require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'stubs/adapter_stub'

class SystemKernelTest < Test::Unit::TestCase
  
  include ActiveMessaging::Test::Fixtures
  
  def test_load_broker_yml    
    
    ActiveMessaging::System.environment = :test
    
    ActiveMessaging::System.configure do |my|
      my.broker_yml fixture_path('broker.yml')
    end
    
    b1 = ActiveMessaging::System.registry_entry( :broker, :broker1 )
    
    assert_kind_of ActiveMessaging::Broker, b1, 
      "Expected the broker to be registered"
    
    assert_kind_of AdapterStub, b1.adapter, "Expected the correct adapter " + 
      "to be registered with the broker."
  end
  
end