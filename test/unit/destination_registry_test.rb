require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'stubs/adapter_stub'
require 'mocks/mock_broker_registry'

class DestinationRegistryTest < Test::Unit::TestCase

  include ActiveMessaging::Test::Fixtures
  
  def setup
    ActiveMessaging.reset!
    @broker_registry = MockBrokerRegistry.new
    @registry = ActiveMessaging::DestinationRegistry.new( @broker_registry )
    @config = yml_fixture('configure_destinations')
    @config.symbolize_keys!(:deep)
  end
  
  def test_configure_destinations
    
    @broker_registry.expect( :dest1, "/queue/Destination1", 
                              { :header1 => 'value1',
                                :header2 => 'value2' })
    @broker_registry.expect( :dest2, "/queue/Destination2", nil)
    
    @registry.configure( @config[:destination] )
    
    verify_mock @broker_registry
    
  end 
  
  
end

