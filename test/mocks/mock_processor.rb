class MockProcessor
  include Test::Unit::Assertions
  
  attr_reader :call_count
  
  def expect(count, message, headers = {} )
    @expected_message = message
    @expected_headers = headers
    @expected_count   = count
    self
  end
  
  def process!(message)
    @received_message = message.body
    @call_count += 1
  end
  
  def verify!
    assert_equal @expected_count, @call_count, 
      "#process! was called too few or too many times." 
    assert_not_nil @received_message, "Did not receive a message."
    assert_equal @expected_message, @received_message, "Message body garbled."
    # TODO verify headers
  end
  
  # An instance can act like a class
  def new
    @call_count = 0
    self
  end
  
  def name
    self.class.name
  end  
  
end