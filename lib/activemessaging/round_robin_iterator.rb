  module ActiveMessaging
    
    class RoundRobinIterator < BaseIterator

      def select_next
        @index ||= -1                      # initialize if necessary
        @index += 1                        # increment counter, starting at 0 
        @index = 0 if @index == pool.size  # start over at end of array
        return pool[@index]      
      end
      
      def to_s
        self.class.name
      end
      
    end
    
  end