class MockProcessor
  include Test::Unit::Assertions
  
  attr_reader :call_count
  
  def expect(message, headers = {}, count = 1)
    @expected_message = message
    @expected_headers = headers
    @expected_count   = count
  end
  
  def process!(message)
    @received_message = message.body
    @call_count += 1
  end
  
  def verify!
    assert_equal @expected_message, @received_message, "Message body garbled."
    assert_equal @expected_count, @call_count, 
      "#process! was called too few or too many times." 
    # TODO verify headers
  end
  
  # An instance can act like a class
  def new
    @call_count = 0
    self
  end
  
end