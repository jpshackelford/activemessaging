require 'stubs/poller_thread_stub'

class MockStrategy
  
  include Test::Unit::Assertions
  
  def initialize
    @call_delay_count = 0    
    @thread_targets = [:a, :b, :c ]
    @created_threads = []
    @expected_creation_count = nil
    @expected_execution_count = nil
  end
  
  def delay_n_calls( count )
    @call_delay_count = count
  end
  
  def thread_targets_are( *args )
    @thread_targets = args
  end
  
  def expect_thread_creation_count(count)
    @expected_creation_count = count
  end
  
  def expect_thread_execution_count(count)
    @expected_execution_count = count
  end
  
  def created_thread_count_should_be( count )
    assert_equal count, @created_threads.size,
        "Expected to create #{count} threads, but created " + 
        "#{@created_threads.size} threads."      
  end
  
  def executed_thread_count_should_be( count )
    assert_equal count, @created_threads.select{|t| t.ran? }.size,
      "Expected #{count} threads to run, but " +
      "#{@created_threads.select{|t| t.ran?}.size} actually ran."
  end
  
  def verify!
    
    if @expected_creation_count
      created_thread_count_should_be @expected_creation_count
    end
    
    if @expected_execution_count 
      executed_thread_count_should_be @expected_execution_count
    end
    
  end
  
  
  def target_thread_identities
    unless @call_delay_count == 0
      @call_delay_count -= 1
      return []
    else
      return @thread_targets
    end
  end
  
  def identify( thread )
    thread.name
  end
  
  def create_thread( id )
    t = PollerThreadStub.new( id )
    @created_threads  << t
    return t
  end
  
end