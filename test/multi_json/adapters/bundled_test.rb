# frozen_string_literal: true

require 'test_helper'

  module Adapters
    class BundledTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_options
        MultiJson.use :bundled
        result = MultiJson.load('{"a":1}')
        expected = { a: 1 }
        assert_equal expected, result
      end
  end
end
