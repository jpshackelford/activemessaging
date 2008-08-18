require 'yaml'

require File.expand_path( File.dirname(__FILE__) + '/../framework/dir_structure' )
require 'framework/fixtures'

include ActiveMessaging::Test::Fixtures

# configure_destinations.yml
def configure_destinations_yml
  h = { 'destination' => {
          'destinations' => {
            'dest1' => { 'destination' => '/queue/Destination1', 
                         'headers'     => {'header1'=>'value1', 'header2'=>'value2'}, 
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

# configure_processors.yml
def configure_processors_yml
  h = { 'processor' => {
          'processors' => [
          
            # one destination, one processor
            { 'destination' => 'destination1',
              'class'       => 'MockProcessor1',
              'headers'     => {'key1' => 'value1', 'key2' => 'value2'},
              'require'     => 'mocks/mock_processor'},
            
            # one destination, two processors  
            { 'destination' => 'destination2', 'class' => 'MockProcessor2'},
            { 'destination' => 'destination2', 'class' => 'MockProcessor3'},
            
            # two destinations, one processor
            { 'destination' => 'destination3', 'class' => 'MockProcessor4'},
            { 'destination' => 'destination4', 'class' => 'MockProcessor4'} ]
       }}  
  open(fixture_path('configure_processors.yml'),'wb'){|f| YAML.dump(h,f)}     
end

configure_destinations_yml
configure_brokers_yml
configure_processors_yml
