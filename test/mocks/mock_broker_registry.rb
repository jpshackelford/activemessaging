class MockBrokerRegistry
  
  include Test::Unit::Assertions
  
  def initialize
    @expected_destinations = []
    @registered_destinations = []
    @validate_calls = 0
  end
  
  def expect( *args )
    @expected_destinations << args
    return self
  end
  
  def[](name)
    self
  end
  
  def name
    "mock_destination_#{@registered_destinations.size}".to_sym 
  end
  
  def adapter
    self
  end
  
  def freeze
    self
  end

  def new_destination(*args)
    @registered_destinations << args
    return self
  end

  def validate!
    @validate_calls += 1  
  end
  
  def verify!
    
    @expected_destinations.sort!
    @registered_destinations.sort!
    
    @expected_destinations.each_with_index do |expected, index|
    assert_equal expected, @registered_destinations[index],
      "Failed to register the expected destinations."
    end
    
    assert_equal @registered_destinations.size, @validate_calls,
      "Failed validate each of the destinations registered."
  end

  def to_s
    self.class.name
  end
  
end