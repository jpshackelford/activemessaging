require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

class MyProcessor < ActiveMessaging::BaseProcessor; end

class MyModel;  end

class BaseProcessorTest < Test::Unit::TestCase   
  
  def setup
    @processor1 = MyProcessor
  end
  
  def test_message_is_directive
    @processor1.message_is :MyModel
    assert_equal( MyModel, @processor1.model_class )  
  end
  
end