Files in this directory are *not* automatically required during testing.
To explicity require them first require test_helper and then issue require
statements relative to the test directory, e.g.

    require 'mocks/mock_processor'
