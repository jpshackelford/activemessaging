module ActiveMessaging #:nodoc:
  module CoreExtensions #:nodoc:
    module Hash #:nodoc:
      module Keys
       
        # Destructively convert all keys to symbols.
        def symbolize_keys!( depth=:shallow )
          inject(self) do |hash, (key, value)|
            
            if depth == :deep
              case value
              when ::Hash
                value.replace( value.symbolize_keys!(:deep) )
              when ::Array
                value.map do |e| 
                  e.symbolize_keys!(:deep) if e.kind_of?(::Hash)
                  e
                end
              end  
            end
            
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

