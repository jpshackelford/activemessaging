module ActiveMessaging
  module Test
    module Fixtures
            
      def fixture_path( *args )
        ActiveMessaging.test_path( 'fixtures', *args )
      end
      
      def fixture( filename )
        File.open( fixture_path(filename), 'rb'){|f| f.read}
      end
      
      def yml_fixture( filename )        
        YAML.load_file( fixture_path(filename + '.yml') )
      end
      
    end
  end
end
