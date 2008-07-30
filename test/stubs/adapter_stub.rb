class AdapterStub
  attr_accessor :reliable, :poll_interval, :tx_timeout
  
  def initialize
    @poll_interval = 1
    @reliable      = true
  end
  
  def configure( options = {})
    @poll_interval = options[:poll_interval]  || @poll_interval 
    @reliable      = options[:reliable]       || @reliable 
    @tx_timeout    = options[:tx_timeout]     || @tx_timeout 
  end
  
  def new_destination( name, destination, headers )
  end
  
  def to_sym
    :adapter_stub
  end
  
  # called to cleanly get rid of connection
  def disconnect
    nil
  end
end