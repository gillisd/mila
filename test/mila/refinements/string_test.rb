# frozen_string_literal: true

require 'test_helper'

module Mila
  module Refinements
    class StringTest < Minitest::Test
      using Refinements::String

      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_camelize
        assert_equal 'HelloWorld', 'hello_world'.camelize
        assert_equal 'Person', 'person'.camelize
        assert_equal 'CamelCaseString', 'camel_case_string'.camelize
        assert_equal '', ''.camelize
      end

      def test_underscore
        assert_equal 'hello_world', 'HelloWorld'.underscore
        assert_equal 'person', 'Person'.underscore
        assert_equal 'camel_case_string', 'CamelCaseString'.underscore
        assert_equal 'already_underscored', 'already_underscored'.underscore
        assert_equal '', ''.underscore
      end

      def test_dasherize
        assert_equal 'hello-world', 'hello_world'.dasherize
        assert_equal 'multiple-underscores-replaced', 'multiple_underscores_replaced'.dasherize
        assert_equal 'no-change', 'no-change'.dasherize
        assert_equal '', ''.dasherize
      end

      def test_titleize
        assert_equal 'Hello World', 'hello_world'.titleize
        assert_equal 'Person', 'person'.titleize
        assert_equal 'Camel Case String', 'camel_case_string'.titleize
        assert_equal '', ''.titleize
      end

      def test_to_pathname
        path = '/tmp/file.txt'
        pathname = path.to_pathname

        assert_instance_of ::Pathname, pathname
        assert_equal path, pathname.to_s
      end

      def test_to_h
        json_string = '{"key": "value"}'
        hash = json_string.to_h

        assert_instance_of Hash, hash
        assert_pattern { hash => { key: 'value' } }
      end

      def test_increment_version
        assert_equal '1.0.1', '1.0.0'.increment_version
        assert_equal '2.4.6', '2.4.5'.increment_version
        assert_equal '1.3', '1.2'.increment_version
        assert_equal '10.0.1', '10.0.0'.increment_version
        assert_equal '0.0.1', '0.0.0'.increment_version
      end

      def test_increment_version_edge_cases
        assert_equal '1', '0'.increment_version
        assert_equal '1.2.3.4.5.6', '1.2.3.4.5.5'.increment_version
      end
    end
  end
end