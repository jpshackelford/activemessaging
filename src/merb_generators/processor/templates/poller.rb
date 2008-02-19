#!/usr/bin/env ruby
# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

#Try to Load Merb
begin
  require File.expand_path(File.dirname(__FILE__)+'/../config/boot')
  require File.expand_path(File.dirname(__FILE__)+'/../config/merb_init')
rescue LoadError
  # Load Rails
  RAILS_ROOT=File.expand_path(File.join(File.dirname(__FILE__), '..','..','..'))
  load File.join(RAILS_ROOT, 'config', 'environment.rb')
end

# Load ActiveMessaging processors
ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start