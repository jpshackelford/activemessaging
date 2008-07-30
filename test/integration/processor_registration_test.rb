require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

class ProcessorRegistrationTest < Test::Unit::TestCase
  
  include ActiveMessaging::Test::PollerControl
  
  def setup
    ActiveMessaging.reset!
  end
    
  def test_processor_registered_on_require
    
    # Load a processor and see whether it was automatically registered.
    require 'stubs/processor_stub'
    
    p = registry_entry( :processor, :processor_stub )
    
    assert_not_nil p, "ProcessorStub should have been registered."

    assert_equal ProcessorStub, p.processor_class,
      "ProcessorStub should have been registered on require."
    
    # Determine whether subscriptions are added at the right time.
    # Registering a processor shouldn't automatically register a subscription,
    # we ought to have the destination also. 
    s = registry_entry( :subscription, :hello_world_processor_stub )
    
    assert_nil s, "Subscription entry should not be created until destination "+
                  "is registered."
    
    # Add a destination and see if we get a subscription.
    ActiveMessaging::System.configure do |my|
       my.broker      :reliable_msg
       my.destination :hello_world, '/queue/helloWorld'
    end
    
    s = registry_entry( :subscription, :hello_world_processor_stub )
    
    assert_equal :hello_world_processor_stub, s.name, "Expected to have a " +
      "subscription registered once a processor and destination are registered."
  
  end
  

end