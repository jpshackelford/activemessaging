#!/usr/bin/env ruby
# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

# Load Merb
require File.expand_path(File.dirname(__FILE__)+'/../../../framework/merb/config')
::Merb::Config.parse_args(ARGV)
require File.expand_path(File.dirname(__FILE__)+'/../../../config/boot')
require File.expand_path(File.dirname(__FILE__)+'/../../../config/merb_init')

# Load ActiveMessaging processors
ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start
