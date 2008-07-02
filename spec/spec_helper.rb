require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib activemessaging]))

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib ActiveMessaging]))

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

module FixtureSupport
  
  # return the contents of a fixture file.
  def fixture(file)
    File.open(fixture_path(file),'rb'){|f| f.read}
  end
  
  def fixture_path(filename)
    return File.join(File.dirname(__FILE__), '..', 'fixtures', filename)
  end
    
  # return a REMXML document for a fixture file.
  def xml_fixture(file)
    return REXML::Document.new(fixture(file))
  end
end

include FixtureSupport  
