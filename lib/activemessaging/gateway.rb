module ActiveMessaging
  
  class Gateway
    
    def initialize( destination_registry )
      @destination_registry = destination_registry
    end
    
    # Return a destination by name. Raises a NoDestinationError If no 
    # destination is found.
    def find_destination( destination_name )      
      
      dest = @destination_registry[ destination_name.to_sym ]
      
      raise NoDestinationError, "No destination :#{destination_name} is " + 
        "registered. Registered desintations include " +
        "#{@destination_registry.destination_names.inspect} " if dest.nil?
      
      return dest
    end
    
    # Send a message from to the named destination.
    def publish( destination_name, body, publisher=nil, headers={}, timeout=1 )
      
      LOG.debug "Sending message to #{destination_name}."
      
      raise ArgumentError, "Destination name must not be nil or empty." if 
      destination_name.to_s.empty? 
      
      raise ArgumentError, "Message body must not by nil or empty." if 
       ( body.to_s.empty? )
            
      dest = find_destination( destination_name )
      LOG.debug "Found target destination :#{dest.name}"
      
      details = {
        :publisher   => publisher, 
        :destination => dest,
        :direction   => :outgoing
      }
      
      message_headers = headers.reverse_merge( dest.publish_headers )      
      message = OpenStruct.new( :body    => body, 
                               :headers => message_headers ) 
      begin
        # TODO Timeout seems like a bad idea here, at least without 
        # some kind of call-back hook. At least with the ReliableMgs adapter
        # interrupting a receive can cause a transaction stored in thread local
        # storage to hang out, which can render the thread useless at further
        # functioning and it will eventually raise an exception and die.
        Timeout.timeout(timeout) do
          # execute_filter_chain(:outgoing, message, details) do |message|
            dest.send( message.body, message.headers )
          # end
        end
      rescue Timeout::Error => error
        LOG.error "Timed out trying to send the message #{message} to " + 
                  "destination #{destination_name} via broker " + 
                  "#{dest.broker.name}."
        raise error
      end
    end
    
    # Receive a message from the named destination. Optionally use a block
    # for message processing. Note that if a block is provided the transactional
    # aspects of underlying messaging system are invoked, i.e. a transaction,
    # is committed once the block completes without exception and rolled back
    # if an exception is thrown. The value of the block becomes the return value
    # or if nil, the message is returned. If a block is not provided the message
    # is returned and the receipt of the message is automatically committed. 
    # TODO why the receiver argument?
    def receive( destination_name, receiver=nil, headers={}, timeout=10 )
      
      raise ArgumentError, "Destination name must not be nil or empty." if 
      destination_name.to_s.empty? 
      
      dest = find_destination( destination_name )
      
      # TODO What is this? I found it in the previous implementation
      # but I don't understand what it means.
      headers['id'] = receiver.name.underscore unless 
       (receiver.nil? or subscribe_headers.key? 'id')      
      
      block_value = nil # becomes return value if block_given? and the 
                        # the evaluated block ! nil?      
      begin
        Timeout.timeout( timeout ) do
          message = dest.receive          
          if block_given?
            begin               
              block_value = yield message
            rescue Exception => exception
              dest.unreceive(message, headers )
              raise exception
            else 
              dest.received( message, headers )
            end
          else # no block, so auto commit
            dest.received( message, headers )
          end # block_given?
          return block_value || message 
        end            
      rescue Timeout::Error=> error
        LOG.error "Timed out trying to send the message #{message} to " + 
                "destination #{destination_name} via broker " + 
                "#{dest.broker.name}."
        raise error
      ensure
        dest.broker.disconnect
      end
    end
    
  end # class
end # module