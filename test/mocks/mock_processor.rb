class MockProcessor
  include Test::Unit::Assertions
  
  attr_accessor :call_count, :received_message
  
  def initialize
    @call_count = 0
  end
  
  def expect(count, message, headers = {} )
    @expected_message = message
    @expected_headers = headers
    @expected_count   = count
    self
  end
  
  def process!(message)    
    capture message
    increment_call_count
  end
  
  def capture( message )
    @received_message = message.body
    self.class.single_instance.received_message = message.body if
      self.class.has_expectations?
  end
  
  def increment_call_count
    @call_count += 1     
    self.class.single_instance.call_count += 1 if 
      self.class.has_expectations?
  end
  
  def verify!
    assert_equal @expected_count, @call_count, 
      "#process! was called too few or too many times." 
    assert_not_nil @received_message, "Did not receive a message."
    assert_equal @expected_message, @received_message, "Message body garbled."
    # TODO verify headers
  end
  
  def name
    self.class.name
  end 
  
  # An instance can act like a class
  def new
    @call_count = 0
    self
  end
  
  def instance_methods
    self.methods
  end
  
  # Allow expectations on the class
  class << self
    
    attr_accessor :single_instance
    
    def expect(*args)
      @single_instance = new
      @single_instance.expect(*args)
    end
    
    def has_expectations?
      defined?( @single_instance ) && @single_instance != nil  
    end
    
    def verify!
      @single_instance.verify!
      @single_instance = nil
    end
    
  end
  
end # class

# Additional processor classes for use in testing setup of 
# processor registry where multiple processor entries exist.
4.times do |n|
  class_name = "MockProcessor#{n+1}".to_sym
  # if the constant has not been defined, define it 
  begin
    Object.const_get( class_name )
  rescue NameError
    Object.const_set(class_name, Class.new(MockProcessor))        
  end         
end
