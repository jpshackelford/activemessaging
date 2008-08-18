require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

begin
  require 'reliable-msg'
rescue LoadError
else
  #
  class PollerHotConfigurationTest < Test::Unit::TestCase
    
    include ActiveMessaging::Test::ReliableMsg
    include ActiveMessaging::Test::PollerControl
    include ActiveMessaging::Test::Fixtures
    
    def setup           
      start_reliable_messaging

      ActiveMessaging.reset!  
      start_poller
      
      ActiveMessaging::System.configure do |my|
        my.destination :poller_config, '/topic/poller_config'
        my.processor   :poller_config, ActiveMessaging::ConfigurationProcessor
      end            
    end
    
    def teardown
      stop_poller
      stop_reliable_messaging
    end
        
    def test_configure_destinations
      
      # fixture contains two destinations in order to demonstrate that
      # configuration messages can handle more than one at a time.
      
      # send the message
      publish :poller_config, fixture('hot_configure_destinations.yml')
      
      # wait a reasonable length of time for the message to be
      # picked up and processed
      sleep 2
      
      # see that we've registered them
      d1 = registry_entry( :destination, :dest1 )
      d2 = registry_entry( :destination, :dest2 )
      
      assert_not_nil d1, "Destination 1 was not registered."
      assert_not_nil d2, "Destination 2 was not registered."
      
      # Ensure that they were registered correctly
      verify_destination( d1, "/queue/Destination1")
      verify_destination( d2, "/queue/Destination2")
      
    end
  
#    def test_configure_brokers
#      flunk "Not implemented"
#    end    
#    
#    def test_configure_processors
#      flunk "Not implemented"
#    end
#    
#    def test_register_multiple_types_at_once
#      flunk "Not implemented"
#    end
    
    
    private
    
    def verify_destination(destination, expected_dest_string)
      
      assert_kind_of ActiveMessaging::BaseDestination, destination, 
      "Should have registered a destination."
      
      assert_equal destination.destination, expected_dest_string, 
        "Destination grabled during registration."
      
    end      
    
    
    
    
  end
  
end