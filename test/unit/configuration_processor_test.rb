require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )
require 'mocks/mock_kernel'

class ConfigurationProcessorTest < Test::Unit::TestCase
  
  include ActiveMessaging::Test::Fixtures
  include ActiveMessaging::Test::PollerControl  
  
  def setup
    @processor = ActiveMessaging::ConfigurationProcessor.new
    @mock_kernel = MockKernel.new
    silence_warnings do
      @real_kernel = ActiveMessaging::System
      ActiveMessaging.const_set( :System, @mock_kernel)    
    end
  end
  
  def teardown
    silence_warnings do
      ActiveMessaging.const_set( :System, @real_kernel)    
    end
  end
  
  def test_on_message
    
    # fixture contains two destinations in order to demonstrate that
    # configuration messages can handle more than one at a time.
    @mock_kernel.expect_configure_message yml_fixture('configure_destinations')   

    @processor.on_message fixture('configure_destinations.yml')

    verify_mock @mock_kernel    
  end
  
end