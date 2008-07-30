class MockKernel
  
  include Test::Unit::Assertions

  def expect_configure_message( message )
    @expected_message = message
  end

  def configure
    yield self    
  end
  
  def configuration( hash )
    @configuration_message = hash
  end

  def verify!
    assert_equal @expected_message, @configuration_message, 
      "Failed to receive expected message"
  end

end  