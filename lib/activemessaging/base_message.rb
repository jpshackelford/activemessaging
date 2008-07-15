module ActiveMessaging
  class BaseMessage
    
    VIRTUAL_TOPIC = /VirtualTopic\.(.*)/
    
    attr_accessor :headers, :body, :command
    
    def initialize( headers, body, destination_name, command='MESSAGE')
      @headers = headers || {}
      @body    = body
      @command = command
      headers['destination'] = destination_name
    end
    
    def route_to?( destination )
      
      # virtual topic support introduced by Cliff Moon.
      unless destination.destination =~ VIRTUAL_TOPIC && 
             virtual_topic = $1 &&
             @headers[:destination].to_s =~ VIRTUAL_TOPIC
      
        # typical matching
        LOG.debug "Does destination match? #{@headers[:destination]} == " + 
                  "#{destination.destination}"
        return @headers[:destination].to_s == destination.destination.to_s        
        
      else
      
        # virtual_topic matching
        LOG.debug "Does VirtualTopic match, i.e. #{virtual_topic} == #{$1}?"
        return virtual_topic == $1
      end
    end
    
    def to_s
      "<Base::Message body='#{body}' headers='#{headers.inspect}' command='#{command}' >"
    end
    
  end
  
end