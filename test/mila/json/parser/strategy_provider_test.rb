# frozen_string_literal: true

require 'test_helper'

module Mila
  module JSON
    class Parser::StrategyProviderTest < Minitest::Test
      attr_reader :test_string

      def setup
        @subject = Parser::StrategyProvider.instance
        @test_string = '{"key": "value"}'
        @expected_stringified = { 'key' => 'value' }
        @expected_symbolized = { key: 'value' }
      end

      def test_define_parser
        @subject.define_parser :test_parser do |builder|
          builder.parse do |string, **options|
            ::JSON.parse(string, **options)
          end

          builder.dump do |object|
            ::JSON.dump(object)
          end
        end

        parser = @subject.parser_strategy(:test_parser)

        assert_equal @expected_stringified, parser.parse(test_string)
      end

      def test_format_symbol
        @subject.define_parser :test_regular do |builder|
          builder.symbol_mapping = :symbolize_names
          builder.parse do |string, **options|
            ::JSON.parse(string, **options)
          end

          builder.dump do |object|
            ::JSON.dump(object)
          end
        end

        parser = @subject.parser_strategy(:test_regular)
        result = parser.parse(test_string)
        assert_equal [:key], result.keys
      end

      def test_format_string
        @subject.define_parser :test_string do |builder|
          builder.symbol_mapping = :symbolize_names
          builder.parse do |string, **options|
            ::JSON.parse(string, **options)
          end

          builder.dump do |object|
            ::JSON.dump(object)
          end
        end

        parser = @subject.parser_strategy(:test_string)
        result = parser.parse(test_string, format: :string)
        assert_equal ['key'], result.keys
      end

      def test_js_parser
        parser = @subject.parser_strategy(:js)
        result = parser.parse(test_string)

        assert_equal @expected_stringified.transform_keys(&:to_s), result
      end

      def test_js_parser_reuses_context
        @subject.define_parser :test do |builder|
          context = [:one, :two]
          builder.parse do |_|
            context.shift
          end
        end
        result_1 = @subject.parser_strategy(:test).parse(test_string)
        assert_equal :one, result_1

        result_2 = @subject.parser_strategy(:test).parse(test_string)
        assert_equal :two, result_2
      end
    end
  end
end
