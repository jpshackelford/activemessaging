require File.join(File.dirname(__FILE__), %w[spec_helper])
require 'stringio'

describe ActiveMessaging::Initializer do
  
  LOG_FILE = 'logger_init_test.log'
  
  before do
    @init = ActiveMessaging::Initializer.new
  end
  
  after do    
    
    # clean up file system changes we make in testing
    File.delete(LOG_FILE) if File.exist?(LOG_FILE)
    
    # clean up environment variables we modifying in testing
    ENV['AM_ENV'] = nil
    
    # reverses impact of #initialize_system_globals
    Kernel.silence_warnings do
      ActiveMessaging.const_set(:System, nil)
    end 
    
  end

  it "boots a client" do
    violated 
  end

  it "boots a server" do
    violated
  end
  
  it "provides a method for adding configuration entries" do
    @init.configure :my_entry => :some_value
    @init[:my_entry].should == :some_value     
  end

  it "merges new configuration entries with previous ones" do
    @init.configure :entry_1 => :value_1
    @init.configure :entry_2 => :value_2
    @init[:entry_1].should == :value_1
    @init[:entry_2].should == :value_2
  end
  
  it "merges configurations one level deep." do
    
    @init.configure :entry_1 => { :sub_entry_1 => 1, 
      :sub_entry_2 => 0 }
    
    @init.configure :entry_1 => { :sub_entry_2 => 1,
      :sub_entry_3 => 1}
    
    @init[:entry_1].should == { :sub_entry_1 => 1,
      :sub_entry_2 => 1,
      :sub_entry_3 => 1 }
  end
  
  it "can be configured from a file" do
    @init.configure(@init.load( fixture_path('sample.yml')))
    @init[:entry].should == {:sub_entry => 'value'}
  end
  
  
  it "initializes a logger if no configuration is provided" do
    @init.initialize_logger
    @init.initialize_system_globals
    ActiveMessaging::System.logger.should be_a_kind_of(Logger)
  end
  
  it "use the logger specified in the configuration" do
    myio = StringIO.new
    
    @init.configure( :logger => Logger.new(myio))
    @init.initialize_logger
    @init.initialize_system_globals
    
    ActiveMessaging::System.logger.info("this is a test")
    myio.string.should match(/this is a test/)    
  end
  
  it "initialize a logger when config is provided as a String" do
    
    @init.configure( :logger => "Logger.new('logger_init_test.log')")
    @init.initialize_logger
    @init.initialize_system_globals
    
    ActiveMessaging::System.logger.info("this is a test")
    ActiveMessaging::System.logger.close
    
    open 'logger_init_test.log' do |f|
      f.read.should match(/this is a test/)
    end
  end
  
  it "determines environment from the AM_ENV environment variable" do
    ENV['AM_ENV'] = 'myenv'
    @init.initialize_environment_selection
    @init.initialize_system_globals
    
    ActiveMessaging::System.selected_environment.should == :myenv        
  end 
  
  it "determines environment from config file if env variable is not set" do
    @init.initialize_environment_selection
    @init.initialize_system_globals
    ActiveMessaging::System.selected_environment.should == :production
  end
    
  it "default poller initialized in object repository" do
    with_default_registry_for( :poller ) do |it|
      it.should be_kind_of( ActiveMessaging::Poller )
    end
  end
  
  it "default connection manager configured in object repository" do
    with_default_registry_for( :brokers ) do |it|
      it.should be_kind_of( ActiveMessaging::ConnectionManager )
    end  
  end
  
  it "default destination registry configured in object repository" do
    with_default_registry_for( :destinations ) do |it|
      it.should be_kind_of( ActiveMessaging::DestinationRegistry )
    end  
  end

  it "default processor pool configured in object repository" do
    with_default_registry_for( :processor_pool ) do |it|
      it.should be_kind_of( ActiveMessaging::ProcessorPool )
    end  
  end

  it "default gateway configured in object repository" do
    with_default_registry_for( :gateway ) do |it|
      it.should be_kind_of( ActiveMessaging::Gateway )
    end  
  end
  
  it "configures a gateway" do
    consume_logging_messages
    @init.initialize_object_registry
    @init.initialize_gateway
    @init.initialize_system_globals
    ActiveMessaging::System.gateway.should be_configured
  end
  
  it "initializes a processor pool" do
    consume_logging_messages
    @init.initialize_object_registry
    @init.initialize_system_globals
    ActiveMessaging::System.processor_pool.should be_configured
  end
  
  it "configures custom objects" do
    violated
  end
  
  private
   
  # auxiliary method for testing of default entries in
  # object registry initialization
  def with_default_registry_for( entry )
    consume_logging_messages
    @init.initialize_object_registry
    @init.initialize_system_globals    
    yield registry[entry]    
  end
  
  def clear_registry_configuration
    @init.configure(:object_registry => nil)    
  end
  
  def registry
    ActiveMessaging::System.instance_variable_get(:@object_registry)    
  end
  
  def consume_logging_messages
    @init.configure(:logger => ActiveMessaging::NullLogger)    
    @init.initialize_logger
  end

end