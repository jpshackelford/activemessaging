module ActiveMessaging #:nodoc:
  module CoreExtensions #:nodoc:
    module Hash #:nodoc:
      module Keys
       
        # Destructively convert all keys to symbols.
        def symbolize_keys!( depth=:shallow )
          inject(self) do |hash, (key, value)|
            
            value.replace( value.symbolize_keys!(:deep) ) if 
              depth == :deep && value.kind_of?( ::Hash )
            
            begin
              sym = key.to_sym
              hash[sym] = value
            rescue Exception
              # ignore
            else
              hash.delete(key) unless key.kind_of? Symbol
            end
            hash
          end # inject
          return self
        end

      end
    end
  end
end

