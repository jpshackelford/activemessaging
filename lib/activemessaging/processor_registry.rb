module ActiveMessaging
  
  class ProcessorRegistry < BaseRegistry
  
    def create_item( destination_name , processor_class, headers = {}, options = {} )
      p = ProcessorReference.new( destination_name, processor_class, headers, options)
      p.validate!
    end
    
  end
  
  class ProcessorReference
    
    attr_reader :destination_name, :processor_class, :headers, :options
    
    def initialize( destination_name , processor_class, headers = {})
      @destination_name = destination_name.dup.freeze
      @processor_class  = processor_class
      @headers          = headers.dup.freeze
    end
    
    def validate!
      
      raise ArgumentError, "Processors must respond to #process!" unless 
        processor_class.new.respond_to?( :process! )
      
    end
    
    # add factory logic and methods on ProcessorBase for reentrant processors
  end
  
  
end