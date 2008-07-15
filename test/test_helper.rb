# Provide shortcuts for finding our way around the project tree
module ActiveMessaging
  
  TEST_DIR = File.dirname(__FILE__)
  LIB_DIR  = File.expand_path( File.join(TEST_DIR, %w[.. lib]))
  
  class << self
    
    def path(dir,*args)
      p = [dir]
      p += args
      File.expand_path(File.join(*p))  
    end

    def lib_path(*args)
      path(LIB_DIR,*args)
    end

    def test_path(*args)
      path(TEST_DIR,*args)
    end
    
  end  
end

# Require ActiveMessaing library
require ActiveMessaging.lib_path('activemessaging')

# Add the testing directory to the load path
$LOAD_PATH.unshift( ActiveMessaging::TEST_DIR )

# load libraries used for testing
require 'test/unit'
require 'fileutils'

# load ActiveMessaging test framework
require 'framework/logging'

# setup a logger for this test run.
include ActiveMessaging::Test::Logging 
logger = new_test_logger
ActiveMessaging::System.logger = logger 
