# frozen_string_literal: true

require 'test_helper'

module Mila
  module JSON
    class Scanner::JsStrategyTest < Minitest::Test
      using Refinements::String

      def setup
        @subject = Scanner::JsStrategy.new
      end

      def test_embedded_curly
        string = ::JSON.generate({ "a": "this has an unmatched } character in a string" })
        results = @subject.scan(string)

        assert_equal 1, results.size

        result_hashes = results.map(&:to_h)
        assert_pattern { result_hashes => [{ a: "this has an unmatched } character in a string" }] }
      end
    end
  end
end
