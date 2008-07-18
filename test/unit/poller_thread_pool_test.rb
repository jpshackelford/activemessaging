require File.expand_path( File.dirname(__FILE__) + '/../test_helper' )

require 'mocks/mock_strategy'

# Tests poller for one broker, one destination, and one message using
# ReliableMsg broker.
class PollerThreadPoolTest < Test::Unit::TestCase 

  def setup 
    @strategy = MockStrategy.new
    @poller_thread_pool = ActiveMessaging::PollerThreadPool.new( @strategy )    
  end
  
  def test_responds_to_stop_quickly
    
    @strategy.thread_targets_are :a, :b, :c
    @strategy.expect_thread_execution_count( 0 )
    
    @poller_thread_pool.start
    @poller_thread_pool.stop
    
    verify_mock @strategy
  end

  def test_poller_waits_for_configuration

    @strategy.delay_n_calls( 1 )
    @strategy.thread_targets_are :a, :b          # <-- Arbitrary values.
    @strategy.expect_thread_execution_count( 2 ) # <-- Should match above number 
                                                 #     of arguments above.
    
    t = Thread.start do
      @poller_thread_pool.start
      @poller_thread_pool.block
    end
    
    sleep 0.2 # pause a moment for the poller to start.
    
    assert_equal true, t.alive?, "Poller should block, even if strategy " +
      "doesn't immediately identify threads."
      
    assert_equal true, @poller_thread_pool.running?,
      "Poller should be considered running even if the strategy doesn't " +
      "immediately identify target threads."
    
    # Since the strategy is delaying we shouldn't have created any
    # threads yet.
    @strategy.executed_thread_count_should_be( 0 )
    
    # Tell the thread pool to check with the strategy again. and wait for a
    # moment so that threads will have an opportunity to execute.
    @poller_thread_pool.update(:add, nil)
    sleep 0.2
    
    # verify that expectations are met.
    verify_mock @strategy

    @poller_thread_pool.stop
  end
  
end


