require 'qpid'
# require "/Users/cliff/projects/qpid/src/lib/qpid"

module ActiveMessaging
  module Adapters
    module Amqp
      class Connection
        include ActiveMessaging::Adapter
        include Qpid
        register :amqp
        
        @@mutex = Mutex.new
        @@channel_number = 0
        
        def initialize(cfg)
          @retryMax = cfg[:retryMax] || 0
          @deadLetterQueue = cfg[:deadLetterQueue] || nil
          @spec = Powerset::Qpid.load_spec("amqp.0-8")
          cfg[:login] ||= 'guest'
          cfg[:realm] ||= nil
          cfg[:passcode] ||= 'guest'
          cfg[:host] ||= 'localhost'
          cfg[:port] ||= 5672
          cfg[:reliable] ||= false
          cfg[:reconnectDelay] ||= 5
          @cfg = cfg
          @consumer_tags = {}
          start_connection
        end
        
        def received(message, headers={})
          channel.basic_ack(message.headers[:delivery_tag])
        end
        
        def unreceive(message, headers={})
          channel.basic_reject(:delivery_tag => message.delivery_tag)
        end
        
        def receive
          while true
            #we need to ensure the channel is open
            #channel
            @consumer_tags.each do |queue_name, ctag|
              queue = @@client.queue(ctag)
              next if queue.empty?
              thing = queue.pop
              return wrap_msg(thing, queue_name)
            end
            sleep 0.2
          end
        end
        
        def send(routing_key, body, headers={})
          # puts "in send"
          exchange = headers[:exchange]
          content = Qpid::Content.new(headers, body)
          channel.basic_publish(:routing_key => routing_key, :exchange => exchange, :content => content)
        end
        
        #weird.  so how do we dispatch correctly?
        def subscribe(queue_name, headers={}, subId=nil)
          # puts "in subscribe #{queue_name} #{headers.inspect}"
          exchange = headers[:exchange] || nil
          routing_key = headers[:routing_key] || queue_name
          channel.queue_declare(:queue => queue_name)
          channel.queue_bind(:queue => queue_name, :exchange => exchange, :routing_key => routing_key)
          @consumer_tags[queue_name] = channel.basic_consume(:queue => queue_name).consumer_tag
        end
        
        def unsubscribe(queue_name, headers={}, subId=nil)
          # puts "in unsubscribe #{queue_name} #{headers.inspect}"
          ctag = @consumer_tags.delete(queue_name)
          channel.basic_cancel(ctag)
        end
        
        def disconnect(headers={})
          # puts "in disconnect #{headers.inspect}"
          channel.channel_close
        end
        
        private
        
        def wrap_msg(amqp_msg, queue_name)
          content = amqp_msg.content
          headers = [:consumer_tag, :delivery_tag, :redelivered, :exchange, :routing_key].inject({}) do |hd, key|
            hd[key] = (amqp_msg.send(key) rescue nil)
            hd
          end
          headers[:destination] = queue_name
          AmqpMessage.new(content.body, headers.merge(content.headers))
        end
        
        def channel
          if !@channel || @@client.failed# || @@client.really_closed?
            # puts "starting conn from channel"
            start_connection
          end
          @channel || ChannelStub.new
        end
        
        def start_connection
          # timeout(2) do
          puts "in start connection"
            @@mutex.synchronize do
              if !defined?(@@client) || @failed || @@client.really_closed?
                puts("Attempting reconnect")
                @@client = Client.new(@cfg[:host], @cfg[:port], @spec)
                @@client.start({"LOGIN" => @cfg[:login], "PASSWORD" => @cfg[:passcode]})
              end
            end
            @@channel_number += 1
            @channel = @@client.channel(@@channel_number)
            @channel.channel_open
            @failed = false
          # end
        rescue Object, TimeoutError => boom
          puts boom
          puts("Couldn't connect to broker.")
          @failed = true
          if @cfg[:reliable]
            A13G.logger.warn("Will retry in #{@cfg[:reconnectDelay]}")
            sleep @cfg[:reconnectDelay]
            retry
          end
        end
        
      end
      
      class AmqpMessage
        attr_reader :headers, :command, :body
        
        def initialize(body, headers)
          @body = body
          @headers = headers
          @command = "MESSAGE"
        end
      end
      
      class ChannelStub
        def initialize
          A13G.logger.warn("WARNING stubbing channel")
        end
        
        def method_missing(*args)
          ChannelStub.new
        end
      end
    end
  end
end
