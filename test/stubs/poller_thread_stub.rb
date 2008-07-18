class PollerThreadStub
   
  attr_reader :name
  
  def initialize( name, &block )
    @name = name
    @thread = nil
    @run_flag = true
    @block = block
    @ran = false
  end
  
  def start
    @thread = Thread.start(self) do |thread|
      while( @run_flag == true )
        sleep 0.1
        thread.ran!
      end
    end
  end
  
  def alive?
    @thread.alive?
  end
  
  def join
    @thread.join   
  end
  
  def stop
    @run_flag = false
  end
  
  def ran!
    @ran = true
  end
  
  def ran?
    @ran
  end

end