module MultiJson
  module Adapters
    class Bundled < ::MultiJson::Adapter
      defaults :load, symbolize_keys: true

      ParseError = ::JSON::ParserError

      def load(string, options)
        options[:symbolize_names] = options[:symbolize_keys]
        ::JSON.parse(string, **options)
      end

      def dump(...)
        ::JSON.dump(...)
      end
    end
  end
end