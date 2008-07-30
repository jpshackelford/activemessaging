require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'stubs/adapter_stub'

class BrokerTest < Test::Unit::TestCase
  
    def test_initialize_without_adapter_name
      broker = ActiveMessaging::Broker.new(:name)
      assert_equal :name, broker.adapter_name, 
        "If no adapter is supplied, assume the broker name names the adapter. "
    end

    def test_initialize_with_adapter_name
      broker = ActiveMessaging::Broker.new(:name, :adapter => :adapter)
      assert_equal :adapter, broker.adapter_name, 
        "If an adapter is supplied, use it. "
    end
  
    def test_load_named_adapter     
      broker = ActiveMessaging::Broker.new(:name, :adapter => :adapter_stub)
      assert_kind_of AdapterStub, broker.adapter, 
        "Should have loaded the named adapter."
    end
    
    def test_load_adapter_from_broker_name
      broker = ActiveMessaging::Broker.new( :adapter_stub )
      assert_kind_of AdapterStub, broker.adapter, 
        "Should have infered adapter from broker name and loaded it."
    end
 
end