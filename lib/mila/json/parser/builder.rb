module Mila
  module JSON
    class Parser::Builder
      def initialize(klass)
        @klass = klass
        @klass.default_format = :symbol
      end

      def default_format=(format)
        case format
        in :symbol | :string
          @klass.default_format = format
        else
          raise ArgumentError, "Invalid format: #{format}"
        end
      end

      def symbol_mapping=(mapping)
        @klass.symbol_mapping = mapping
      end

      def string_mapping=(mapping)
        @klass.string_mapping = mapping
      end

      def parse(&block)
        @klass.define_method(:parse) do |string, format: self.class.default_format, **options|
          format_option = format_mappings.fetch(format)
          options.merge!(format_option => true) if format_option
          block.call(string, **options)
        end
      end

      def dump(&block)
        @klass.define_method(:dump, &block)
      end
    end
  end
end