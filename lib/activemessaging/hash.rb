module ActiveMessaging
  
  # A special Hash for use in ActiveMessaging library. Clients will not need it.
  # Note that while several methods are named and behave similarly to those in 
  # ruby facets and Active::Support these methods are not a drop in replacement 
  # as there are some subtle differences of behavior. 
  class Hash < ::Hash    

    # Merge with another hash taking care to merge any hashes nested one level 
    # deep such that:
    #   {:a => {:b => 1, :c => 0 }} merged with 
    #   {:a => {:c => 1, :d => 1 }} equals
    #   {:a => {:b => 1, :c => 1, :d => 1}}    
    def deep_merge!( hash )
      h = ActiveMessaging::Hash.symbolize_keys(hash)
      h.each_pair do | key, nh|
        if nh.kind_of?(::Hash) && self[key].kind_of?(::Hash)
          h[key]= self[key].merge( nh )          
        end        
      end
      self.merge!( h )
    end
    
    class << self
      def symbolize_keys(hash)
        new_hash = hash.dup
        hash.each_pair do |k,v|
          if k.kind_of?(String)                         
            v = symbolize_keys(v) if v.kind_of?(::Hash)
            new_hash.store( k.to_sym, v)
            new_hash.delete(k)
          end
        end
        return new_hash
      end
    end
    
  end
  
end

