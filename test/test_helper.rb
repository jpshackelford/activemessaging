require File.expand_path( File.join( File.dirname(__FILE__), %w[.. lib activemessaging]))

# Provide shortcuts for finding our way around the project tree
# and add the testing directory to the load path.
require File.expand_path( File.dirname(__FILE__) + '/framework/dir_structure' )

# load libraries used for testing
require 'test/unit'
require 'fileutils'

# load ActiveMessaging test framework
require 'framework/logging'
require 'framework/poller_control'
require 'framework/reliable_msg'
require 'framework/mock'
require 'framework/fixtures'

# setup a logger for this test run.
include ActiveMessaging::Test::Logging 
logger = new_test_logger
ActiveMessaging::System.logger = logger 
