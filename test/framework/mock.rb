module Test
  module Unit
    class TestCase
      
      # Invoke the verify! method on any mock objects passed in and count
      # the verification as a single assertion.
      def verify_mocks( *mock_objects )
        mock_objects.each do |mock|
          add_assertion
          mock.verify!
        end
      end
      
      alias verify_mock verify_mocks
      
    end
  end
end
