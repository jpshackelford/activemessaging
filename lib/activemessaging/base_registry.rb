module ActiveMessaging
  
  # Abstract object registry which allows observers to subscribe to adds
  # and deletes of items from the registry. Subclasses should implement
  # #create_item with a factory method which returns an object which responds 
  # to #name. 
  #
  # Note that while adding and removing items from the registry is done in 
  # a thread-safe manner, this class makes no guarantees the timing of event
  # notifications and registration of observers so as to keep dead-lock
  # prevention simple. 
  class BaseRegistry    
    
    def initialize()
      @registry = {}
      @observers = []
      @options = {}
      @lock = Mutex.new   # Mutex is not re-entrant so we use Monitor since
                          # #register calls #notify_observers                          
    end
    
    # Add an item to the registry. args are passed to the #create_item factory
    # method. Observers will receive an update(:add, item) message with a 
    # reference to the newly created item. item#name is considered to be a 
    # unique key for the item in the registry.  Returns the registered item.
    def register( *args )
      LOG.debug "#{self} is attempting to register #{args.inspect}"
      item = create_item( *args )
      unless item.respond_to?( :name )
        raise TypeError, "Return value of #create_item must respond to #name, "+
          "but was a #{item.class.name}."
      end
      @lock.synchronize do
        @registry.store( item.name, item)
        LOG.info "[r] Registered #{item.name} (#{item}) in #{self}."
      end
      notify_observers(:add, item)
      return item
    end

    # Override in subclass
    def configure( options )
      @options = options if options.respond_to? :[]
    end
    
    
    # Remove an item from the registry. Calls item#name for the unique key.
    # used to delete the item from the registry.
    def delete( item )
      LOG.debug "#{self} is attempting to delete #{item.name} (#{item})"
      @lock.synchronize do
        @registry.delete( item.name )
        LOG.debug "Deleted #{item.name} (#{item}) from #{self}."        
      end
      notify_observers(:delete, item)
    end
    
    # Return a list of the names which uniquely identify items in the registry.
    def item_names
      @registry.keys
    end
    
    # Return the named entry. Note that if the entry isn't found and it is the 
    # default, create the default entry. If no name (or a nil name) is 
    # specified, the default entry is returned.
    def [](name=nil)
      # We lazy load the default because we want to be able to specify the 
      # default after the registry has been initialized since initialization of 
      # the registry happens on startup.
      key = name || configured_default
      entry = @registry[ key ]
      if entry != nil
        return entry 
      elsif key == configured_default
        return register_default
      end
    end
    
    def select(&block)
      @registry.values.select(&block)
    end
    
    # Add +observer+ as an observer on this object. +observer+ will now receive
    # notifications. Observers must implement #update(*args)
    def add_observer(observer)      
      unless observer.respond_to? :update
        raise NoMethodError, "observer, #{observer}, needs to respond to #update" 
      end
      LOG.debug "#{self} is attempting to add an observer, #{observer}."
      @observers << observer
      LOG.debug "#{observer} is now listening for events on #{self}."
    end
       
    def to_s
      "#{self.class.name.split('::').last} (#{@registry.size} items, " +
      "#{@observers.size} observers)"   
    end
    
    private
    
    # The symbol key representing the named default entry. Override in subclasses.
    def default_entry
      nil
    end
    
    # Create an entry based on the supplied arguments. Override in subclass
    def create_item( *args )
      raise NotImplementedError.new("Subclasses must implement #create_item")
    end
    
    # Register the #configured_default item. May be overriden in subclasses.
    # Registers and returns the entry which should be considered default for 
    # the registry.
    def register_default
      register( configured_default ) if configured_default
    end
    
    # Return the symbol naming the default entry from the options hash 
    # supplied with the #configure (i.e. options[:default] or else the 
    # entry returned by #default_entry. Instead of overriding this method,
    # override #default_entry or #register_default.
    def configured_default
      @options[:default] || default_entry
    end
    
    def notify_observers(*args)
      @observers.each do |o| 
        LOG.debug "Notifying #{o} of event on #{self}: #{args.inspect}."
        begin
          o.update(*args)
        rescue Exception => e
          # Throw away any exceptions which occur in observers.
          LOG.warn "Caught and ignored exception in observer:\n\t#{e}\n\t" +
                   e.backtrace.join("\n\t") +
                   "\n\tMessage was from #{self} and was #{args.inspect}."              
        end
      end        
    end      
    
  end
end