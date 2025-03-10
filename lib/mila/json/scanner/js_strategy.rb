module Mila
  module JSON
    class Scanner::JsStrategy
      using Refinements::String
      using Refinements::Pathname

      def self.default_source(path = Mila.root.join('json/scanner/js_strategy_impl.js'))
        pathname = path.to_pathname.expand_path
        raise ArgumentError, "File not found: #{pathname}" unless pathname.exist?
        pathname.read
      end

      def initialize(source = self.class.default_source)
        @context = ExecJS.runtime.compile(source)
      end

      def scan(json_string, format: :string)
        case format
        when :string
          extract_strings(json_string)
        when :object
          extract_objects(json_string)
        else
          raise ArgumentError, "Invalid output format: #{format}"
        end
      end

      def extract_strings(json_string)
        results = @context.call('extractJSONStrings', json_string)
        results.map { |result| Mila::JSON::String.new(result) }
      end

      def extract_objects(json_string)
        @context.call('extractJSONObjects', json_string)
      end
    end
  end
end