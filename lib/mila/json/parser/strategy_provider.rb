module Mila
  module JSON
    class Parser::StrategyProvider
      include Singleton

      def self.define_default_parsers(obj)
        obj.define_parser :default do |builder|
          builder.symbol_mapping = :symbolize_names

          builder.parse do |string, **options|
            ::JSON.parse(string, **options)
          end

          builder.dump do |object|
            ::JSON.dump(object)
          end
        end

        obj.define_parser :multi_json do |builder|
          builder.symbol_mapping = :symbolize_keys

          builder.parse do |string, **options|
            ::MultiJson.load(string, **options)
          end

          builder.dump do |object|
            ::MultiJson.dump(object)
          end
        end

        obj.define_parser :raw_oj do |builder|
          builder.parse do |string, **options|
            ::Oj.load(string, **options)
          end

          builder.dump do |object|
            ::Oj.dump(object)
          end
        end

        obj.define_parser :oj do |builder|
          builder.parse do |string, **options|
            MultiJson.use(:oj).tap do |mj|
              mj.load(string, **options)
            end
          end

          builder.dump do |object|
            MultiJson.use(:oj).tap do |mj|
              mj.dump(object)
            end
          end
        end

        obj.define_parser :json_pure do |builder|
          builder.parse do |string, **options|
            MultiJson.use(:json_pure).tap do |mj|
              mj.load(string, **options)
            end
          end

          builder.dump do |object|
            MultiJson.use(:json_pure).tap do |mj|
              mj.dump(object)
            end
          end
        end

        obj.define_parser :raw_json_pure do |builder|
          builder.parse do |string, **options|
            ::JSON.parse(string, **options)
          end

          builder.dump do |object|
            ::JSON.dump(object)
          end
        end

        obj.define_parser :js do |builder|
          parser = Parser::JsStrategy.new
          builder.parse do |string|
            parser.parse(string)
          end

          builder.dump do |object|
            parser.dump(object)
          end
        end
      end

      def parser_strategy(parser)
        @parsers[parser]
      end

      def initialize
        @parsers = {}
        self.class.define_default_parsers(self)
      end

      def set_defaults(&block)
        return if @default_defined
        block.call self
        @default_defined = true
      end

      def define_parser(name, &block)
        klass = Class.new do |c|
          c.singleton_class.attr_accessor :default_format
          c.singleton_class.attr_accessor :symbol_mapping
          c.singleton_class.attr_accessor :string_mapping

          c.attr_reader :format_mappings

          c.define_method :initialize do
            @format_mappings = {
              symbol: c.symbol_mapping,
              string: c.string_mapping
            }
          end

          c.define_method :get_symbol_mapping do
            raise "symbol mapping not defined" unless c.symbol_mapping
            c.symbol_mapping
          end

          c.define_method :get_string_mapping do
            raise "string mapping not defined" unless c.string_mapping
            c.string_mapping
          end

          block.call Parser::Builder.new(c)
        end

        @parsers[name] = klass.new
      end
    end
  end
end