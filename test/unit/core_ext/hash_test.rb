require File.expand_path( File.dirname(__FILE__) + '/../../test_helper' )

class HashTest < Test::Unit::TestCase
  
  def setup
    @h1 = { 'a' => 
          { 'b' =>  
            { 'c' => 1,
              'd' => 2},        
            'e' => 
            { 'f' => 3,
              'g' => 4}
          }
        }    
  end
 
  def test_symbolize_keys_deep
    h2 = { :a => 
          { :b =>  
            { :c => 1,
              :d => 2},        
            :e => 
            { :f => 3,
              :g => 4}
          }
        }
    @h1.symbolize_keys!(:deep)    
    assert_equal h2, @h1
  end
  
  def test_symbolize_keys_shallow
    h2 = { :a => 
          { 'b' =>  
            { 'c' => 1,
              'd' => 2},        
            'e' => 
            { 'f' => 3,
              'g' => 4}
          }
        }  
    @h1.symbolize_keys!    
    assert_equal h2, @h1
  end

end