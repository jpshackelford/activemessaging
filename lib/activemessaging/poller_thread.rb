class PollerThread
  
  attr_reader :name, :scheduler, :dispatcher, :interval, :connection_pool, 
  :run_flag
  
  def initialize(options = {})
    @name                = options[:name]
    @scheduler           = options[:scheduler]
    @dispatcher          = options[:dispatcher]
    @interval            = options[:interval]         || 1.0
    @connection_manager  = options[:connection_manager]
    @thread = nil
    @run_flag = true
  end
  
  def start
    @thread = Thread.start(self) do |my|
      while( my.run_flag == true ) do
          
        # select a destination
        # TODO handle case of no destinations. Do we retry or kill the thread?
        d = my.scheduler.next_destination
        
        # grab a connection
        # TODO error handling
        conn = my.connection_manager.connection( d )
        
        # receive and dispatch the message
        # TODO error handling
        my.dispatcher.dispatch( conn.receive )
        
        # pause
        sleep my.interval
          
      end #while
    end #thread
  end #def
    
  def stop
    @run_flag = false
  end
    
end
