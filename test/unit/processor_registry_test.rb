require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'mocks/mock_processor'

class ProcessorRegistryTest < Test::Unit::TestCase
  include ActiveMessaging::Test::Fixtures  
  
  def setup
    ActiveMessaging.reset!
    @registry = ActiveMessaging::ProcessorRegistry.new
    @config = yml_fixture('configure_processors')
    @config.symbolize_keys!(:deep)
  end
  
  def test_configure_single_processor

    # configure the processor from a fixture
    @registry.configure( @config[:processor] )
    
    # obtain the configured processor
    processor = @registry[:destination1_mock_processor1]
    
    assert_kind_of ActiveMessaging::ProcessorReference, processor, 
      "Expected registry to contain reference to a processor"
    
    assert_equal 'MockProcessor1', processor.processor_class.name, 
      "Expected registry to point to the correct processor class"

    assert_equal :destination1, processor.destination_name, 
      "Expected destination name to be set correctly"
    
    assert_equal({:key1 => 'value1', :key2 => 'value2'}, processor.headers,
      "Expected headers to be properly configured")
    
    # set some expectations for the underlying processor class
    # and send it a message
    message = ActiveMessaging::BaseMessage.new( 'destination1', 'test message' )
    processor.processor_class.expect(1, message.body)
    processor.process!( message )
    
    verify_mock processor.processor_class 
    
  end

  
end