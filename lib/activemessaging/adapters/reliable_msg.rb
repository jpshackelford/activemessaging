unless defined? ActiveMessaging::Adapters::ReliableMsg
  
  require 'reliable-msg'
  
  module ReliableMsg
    class Client
      
      ERROR_INVALID_OPTION = "Invalid option '%s'. Must be one of those in INIT_OPTIONS."
      
      public 
      
      def qm
        if uri = @drb_uri
            # Queue specifies queue manager's URI: use that queue manager.
           @@qm_cache[uri] ||= DRbObject.new(nil, uri)
           if @@qm_cache[uri].alive?
             return @@qm_cache[uri]
           else
             return @@qm
           end
        else
            # Use the same queue manager for all queues, and cache it.
            # Create only the first time.
            @@qm ||= DRbObject.new(nil, @@drb_uri || DEFAULT_DRB_URI)
        end
      end

      alias queue_manager qm

    end # class
        
  end # module
  
  module ActiveMessaging
    module Adapters
      class ReliableMsg
        
        # shorthand
        THREAD_CURRENT_TX = ::ReliableMsg::Client::THREAD_CURRENT_TX
        
        # Adapter specific Message class
        class Message < BaseMessage
          
          attr_accessor :id, :body, :headers, :command, :transaction
          
          def initialize ( id, body, headers, destination_name, 
                          command='MESSAGE', transaction=nil )
            @id                     = id
            @body                   = body 
            @headers                = headers || {}
            @headers[:destination]  = destination_name
            @command                = command
            @transaction            = transaction
          end
          
          def to_s
          "<ReliableMessaging::Message id='#{id}' body='#{body}' " + 
             "headers='#{headers.inspect}' command='#{command}' >"
          end
        end
        
        # Adapter specific Destination
        class Destination < ActiveMessaging::BaseDestination
          
          def initialize( name, destination, publish_headers, broker )
            @name            = name.to_sym
            @destination     = destination
            @publish_headers = publish_headers || {}
            @broker          = broker
            @real_destination = create_real_destination( 
                                                        @destination, @publish_headers ) 
          end
          
          # destination_name string, body string, headers hash
          # send a single message to a destination
          def send( message_body, message_headers={} )
            begin
              @real_destination.put( message_body, message_headers )
            rescue Exception => err
              raise err unless @broker.reliable
              LOG.warn "[A] Send failed, will retry in #{@broker.poll_interval} seconds."
              sleep @broker.poll_interval
              retry
            else
              LOG.debug "[A] Successfully delivered message to :#{name} " + 
                      "via #{@broker}."
            end        
          end
          
          alias publish send
          
          # receive a single message from any of the subscribed destinations
          # check each destination once, then sleep for poll_interval
          def receive
            
            # We'll use thread local variables since we'll need transactional data 
            # to be available to several method calls and we don't want to use 
            # object storage and a mutex since that would block.
            
            raise TransactionError, "Thread should not have another transaction " +
          "in progress. This appears to be a coding error." unless tx.empty?
            
            # start a new transaction
            
            qm = @real_destination.queue_manager
            
            tx.store( :qm, qm ) 
            tx.store( :tid, qm.begin(@broker.tx_timeout))
            LOG.debug "[A] Began transaction #{tx[:tid]}"
            begin
              # now call a get on the destination - it will use the transaction
              #the commit or the abort will occur in the received or unreceive methods
              m = @real_destination.get( @publish_headers[:selector] )
              if m
                return Message.new( m.id, m.object, m.headers, @destination, 
                'MESSAGE', tx )
              else
                commit # transaction not meaningful without a message returned.
                return nil
              end
              
            rescue Exception => error                        
              LOG.debug "[A] Error in receipt of message.\n\t#{error}\n\t#{error.backtrace}"                                   
              abort  #abort the transaction on error            
              raise error unless @broker.reliable            
              return nil           
            ensure
              self.tx = nil
            end
          end        
          
          # called after a message is successfully received and processed
          def received( message, headers={})          
            message.transaction[:qm].commit(message.transaction[:tid])
            LOG.debug "[A] Committed transaction #{message.transaction[:tid]}"
          end
          
          # aborts receipt of message
          def unreceive message, headers={}
            message.transaction[:qm].abort(message.transaction[:tid])
            LOG.debug "[A] Aborted transaction #{message.transaction[:tid]}"
          end
          
          private
          
          def tx
            Thread.current[THREAD_CURRENT_TX] ||= {}
          end
          
          def tx=(val)
            Thread.current[THREAD_CURRENT_TX] = val
          end
          
          def abort          
            tx[:qm].abort( tx[:tid] )
            LOG.debug "[A] Aborted transaction #{tx[:tid]}"
          end
          
          def commit
            tx[:qm].commit( tx[:tid] )
            LOG.debug "[A] Committed transaction #{tx[:tid]}"
          end
          
          def create_real_destination( destination_name, headers )
            dd = /^\/(queue|topic)\/(.*)$/.match(destination_name)
            rm_class = dd[1].titleize
            headers.delete("id")
            return "ReliableMsg::#{rm_class}".constantize.new(dd[2], headers)
          end
          
        end
        
        
        public
        
        #configurable params
        attr_accessor :reliable, :poll_interval, :tx_timeout, :name
        
        def initialize
          @poll_interval = 1
          @reliable      = true
          @tx_timeout    = ::ReliableMsg::Client::DEFAULT_TX_TIMEOUT
          @name          = :reliable_msg
        end
        
        def configure( options = {})
          @poll_interval = options[:poll_interval]  || @poll_interval 
          @reliable      = options[:reliable]       || @reliable 
          @tx_timeout    = options[:tx_timeout]     || @tx_timeout
          @name          = options[:name]           || @name
        end
        
        def new_destination( name, destination, headers )
          Destination.new( name, destination, headers, self )
        end
                
        def to_s
          self.class.name
        end
        
        # called to cleanly get rid of connection
        def disconnect
          nil
        end
        
      end # class
    end # module
  end # module
  
end # unless defined?
