require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ActiveMessaging::ObjectBank do
  
  before do
    @bank = ActiveMessaging::ObjectBank.new
  end
  
  it "initializes objects when configured w/ a class " + 
     "and adds them to the bank" do     
    @bank.create_objects( :my_object => ::TestModule::TestClass )
    @bank.my_object.should be_kind_of ::TestModule::TestClass       
  end

  it "initializes objects when configured w/ a String " + 
     "and adds them to the bank" do     
    @bank.create_objects( :my_object => "::TestModule::TestClass" )
    @bank.my_object.should be_kind_of ::TestModule::TestClass       
  end
  
  it "initializes objects when configured w/ an Object " + 
     "and adds them to the bank" do
    o = ::TestModule::TestClass.new
    @bank.create_objects( :my_object => o )
    @bank.my_object.object_id.should == o.object_id     
  end
  
  it "properly implements respond_to?" do
    @bank.create_objects( :my_object => ::TestModule::TestClass )
    @bank.should respond_to(:my_object)    
  end
  
  it "initializes objects with default values on error" do
    @bank.create_objects( :my_object => "No Such Class", 
                          :my_object => ::TestModule::TestClass)
    @bank.my_object.should be_kind_of ::TestModule::TestClass                      
  end
  
  it "allows hash-like reference to created objects" do
    @bank.create_objects( :my_object => ::TestModule::TestClass )
    @bank[:my_object].should be_kind_of ::TestModule::TestClass      
  end
  
end


module TestModule
  class TestClass    
  end
end