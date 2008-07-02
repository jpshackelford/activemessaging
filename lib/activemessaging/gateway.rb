module ActiveMessaging
  
  class Gateway
    
    attr_writer :connection_manager, :destination_registry
    
    def configured?
      ! ( @connection_manager.nil? || @destination_registry.nil? )
    end
    
  end
end