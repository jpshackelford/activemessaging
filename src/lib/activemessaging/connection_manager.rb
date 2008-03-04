module ActiveMessaging
  class ConnectionManager
    
    def initialize(brokers=[])
      @connection_pools = {}
      @broker_yml = YAML.load_file(File.join(A13G.root, 'config', 'broker.yml'))
      Gateway.named_destinations.each do |name, dest|
        broker_name = dest.broker_name
        unless @connection_pools.has_key?(broker_name)
          @connection_pools[broker_name] = CommonPool::ObjectPool.new({
            :create => lambda {
              create_connection(broker_name)
            },
            :destroy => lambda { |conn|
              conn.disconnect
            }
          }) do |config|
            config.max_active = 20
            config.logger = A13G.logger
          end
        end
      end
    end
    
    #it is important to note that the connections will never get back into the pool
    #from this method
    def connections
      @connection_pools.each do |name, pool|
        conn = pool.borrow_object
        yield(name, conn)
      end
    end
    
    def connection(broker_name)
      begin
        conn = lease_connection(broker_name)
      rescue CommonPoolError
        A13G.logger.warn("Contending for connection")
        sleep(0.001)
        retry
      end
      yield(conn)
      release_connection(broker_name, conn)
    end
    
    def disconnect
      @connection_pools.each do |name, pool|
        pool.each_object do |conn|
          conn.disconnect
        end
      end
    end
    
    private
    
    def lease_connection(broker_name)
      @connection_pools[broker_name].borrow_object
    end
    
    def release_connection(broker_name, connection)
      @connection_pools[broker_name].return_object(connection)
    end
    
    def load_connection_configuration(label='default')
      if label == 'default'
        config = @broker_yml[A13G.environment].symbolize_keys
      else
        config = @broker_yml[A13G.environment][label].symbolize_keys
      end
      config[:adapter] = config[:adapter].to_sym if config[:adapter]
      config[:adapter] ||= :stomp
      return config
    end
    
    def create_connection broker_name='default', clientId=nil
      config = load_connection_configuration(broker_name)
      if clientId
        config[:clientId] = clientId
      end
      Gateway.adapters[config[:adapter]].new(config)
    end
  end
end