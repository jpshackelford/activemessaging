require 'yaml'

require File.expand_path( File.dirname(__FILE__) + '/../framework/dir_structure' )
require 'framework/fixtures'

include ActiveMessaging::Test::Fixtures

# configure_destinations.yml
def configure_destinations_yml
  h = { 'destination' => {
          'destinations' => {
            'dest1' => { 'destination' => '/queue/Destination1', 
                         'headers'     => {}, 
                         'broker'      => :reliable_msg },
            'dest2' => {  'destination' => '/queue/Destination2'}}         
          }
       }  
  open(fixture_path('configure_destinations.yml'),'wb'){|f| YAML.dump(h,f)}     
end

# configure_brokers.yml
def configure_brokers_yml
  h = { 'broker' => {
          'default' => :adapter_stub,
          'brokers' => {
            'env1' => :adapter_stub,
            'env2' => { 'adapter' => :adapter_stub, 'opt1' => 1 },
            'env3' => {
              'broker1' => { 'adapter' => :adapter_stub, 'opt1' => 1 },
              'broker2' => { 'adapter' => :adapter_stub, 'opt1' => 1 }},
          }
       }}  
  open(fixture_path('configure_brokers.yml'),'wb'){|f| YAML.dump(h,f)}     
end

configure_destinations_yml
configure_brokers_yml