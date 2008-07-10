module ActiveMessaging
  
  # Abstract object registry which allows observers to subscribe to adds
  # and deletes of items from the registry. Subclasses should implement
  # #create_item with a factory method which returns an object which responds 
  # to #name. All methods are thread safe.
  class BaseRegistry    
    
    def initialize()
      @registry = {}
      @observers = []
      @lock = Monitor.new # Mutex is not re-entrant and listeners may call back 
                          # to the registry, so we use Monitor to play it safe.
    end
    
    # Add an item to the registry. args are passed to the #create_item factory
    # method. Observers will receive an update(:add, item) message with a 
    # reference to the newly created item. item#name is considered to be a 
    # unique key for the item in the registry. 
    def register( *args )
      Log.debug "#{self} is attempting to register #{args.inspect}"
      item = create_item( *args )
      unless item.responds_to?( :name )
        raise TypeError.new("return value of #create_item must respond to #name")
      end
      @lock.synchronize do
        @registry.store( item.name, item)
        Log.debug "Registered #{item.name} (#{item}) in #{self}."
        notify_observers(:add, item)
      end
    end
    
    # Remove an item from the registry. Calls item#name for the unique key.
    # used to delete the item from the registry.
    def delete( item )
      Log.debug "#{self} is attempting to delete #{item.name} (#{item})"
      @lock.synchronize do
        @registry.delete( item.name )
        Log.debug "Deleted #{item.name} (#{item}) from #{self}."
        notify_observers(:delete, item)
      end
    end
    
    # Return a list of the names which uniquely identify items in the registry.
    def item_names
      @registry.keys
    end
    
    def [](name)
      @registry[name]
    end
    
    def select(&block)
      @registry.values.select(&block)
    end
    
    # Add +observer+ as an observer on this object. +observer+ will now receive
    # notifications. Observers must implement #update(*args)
    def add_observer(observer)      
      unless observer.respond_to? :update
        raise NoMethodError, "observer needs to respond to #update" 
      end
      Log.debug "Adding an observer (#{observer}) to #{self}"
      @lock.synchronize do
        @observers << observer
      end
    end
    
    private
    
    # override in subclass
    def create_item( *args )
      raise NotImplementedError.new("Subclasses must implement #create_item")
    end
    
    def notify_observers(*args)
      Log.debug "Attempting to notify #{self}'s observers."
      @lock.synchronize do
        @observers.each do |o| 
          Log.debug "Notifying #{o} of event on #{self}: #{args.inspect}."
          begin
            o.update(*args)
          rescue Exception => e
            # Throw away any exceptions which occur in observers.
            Log.warn "Caught and ignored exception in observer.\n\t#{e}" +
                     "\n\tMessage was from #{self} and was #{args.inspect}."
          end
        end        
      end
    end      
    
    
  end
end