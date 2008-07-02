require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ActiveMessaging::Hash do
  
  before do
    @h = ActiveMessaging::Hash.new
    @h[:top] = { :a => 1, :b => 'old_val'}
  end
  
  it "merges hashes nested one level deep" do    
    @h.deep_merge!( :top => { :b => 'new_val', :c => 1})
    
    @h[:top].should == { :a => 1, :b => 'new_val', :c => 1 }
  end
  
  it "doesn't have side-effect on #deep_merege!" do    
    # since dup isn't recursive we do this twice
    hash1 = { :top => { :b => 'new_val', :c => 1}}
    hash2 = { :top => { :b => 'new_val', :c => 1}}    
    @h.deep_merge!( hash2 )
    
    hash1.should == hash2
  end

  it "symbolizes keys before performing deep merge" do
    @h.deep_merge!( 'top' => { 'b' => 'new_val', 'c' => 1})

    @h[:top].should == { :a => 1, :b => 'new_val', :c => 1 }
  end
  

end