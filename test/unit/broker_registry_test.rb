require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )
require 'stubs/adapter_stub'

# Tests poller for one broker, one destination, and one message using
# ReliableMsg broker.
class BrokerRegistryTest < Test::Unit::TestCase
  
  include ActiveMessaging::Test::Fixtures
  
  def setup
    ActiveMessaging.reset!
    @registry = ActiveMessaging::BrokerRegistry.new
    @config = ActiveMessaging::System.configure do |my|
      my.file fixture_path('configure_brokers.yml')
    end
  end
  
  def test_auto_register_default_broker
    
    # configure default
    @registry.configure :default => :adapter_stub
    
    # ask for the default broker
    broker = @registry[:adapter_stub]
    
    # Ensure that we have the default in the registry
    # even though we haven't added anything.
    
    assert_not_nil broker, "Default broker should auto register on request"
    
    assert_kind_of ActiveMessaging::Broker, broker, 
      "Registry isn't returning a the correct type for the default broker."
    
    assert_equal :adapter_stub, broker.name, "Wrong broker returned as " + 
      "default." 
    
  end
  
  def test_configure_single_adapter_no_options
    
    ActiveMessaging::System.environment = :env1
    
    @registry.configure( @config[:broker] )
    
    broker =  @registry[:adapter_stub]
    assert_kind_of ActiveMessaging::Broker, broker
    # TODO verify broker options
  end
  
  def test_configure_single_adapter       
    
    ActiveMessaging::System.environment = :env2
    
    @registry.configure( @config[:broker] )
    
    broker =  @registry[:adapter_stub]
    assert_kind_of ActiveMessaging::Broker, broker
    # TODO verify broker options
  end
  
  def test_configure_multiple_adapaters
    
    ActiveMessaging::System.environment = :env3
    
    @registry.configure( @config[:broker] )
    
    assert_kind_of ActiveMessaging::Broker, @registry[:broker1]
    assert_kind_of ActiveMessaging::Broker, @registry[:broker2]
    
    # TODO verify broker options
    # TODO Where in the code do we assume that broker name is adapter name?
    # TODO Remove dead code in base_registry specifically related to brokers. 
  end
  
  def test_no_brokers        
    capture_logging do |logger_io|
            
      ActiveMessaging::System.environment = :env1
      assert_nothing_raised do
        @registry.configure( {} )
        @registry.configure( {:brokers => nil})    
        @registry.configure( {:brokers => {}})
      end
      
      assert_match /No brokers listed/, logger_io.string, 
        "Expected a warning in the Log"
 
    end
  end
  
  def test_nothing_for_environment
    
    ActiveMessaging::System.environment = :none
    
    assert_raise( ActiveMessaging::BadConfigurationException ) do
       @registry.configure( @config[:broker] )
    end
    
  end
  

end