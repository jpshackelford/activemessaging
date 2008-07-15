module ActiveMessaging
  
  class CustomClassRegistry < BaseRegistry
    def create_item(name, ruby_class)
      CustomClassRef.new( name, ruby_class )
    end
  end
  
  class CustomClassRef
    attr_reader :name, :class
  
    def initialize( name, ruby_class)
      @name = name
      @class = ruby_class
    end
    
    def new(*args)
      @class.new(*args)
    end
  
    def to_s
      "CustomClassRef(:#{@name} #{@class.name}"
    end
  end
  
end