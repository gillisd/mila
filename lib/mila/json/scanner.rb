module Mila
  module JSON
    class Scanner
      def initialize(strategy = StrategyProvider.instance.js_strategy)
        @strategy = strategy
      end

      def scan(json_string, format: :string)
        @strategy.scan(json_string, format: format)
      end
    end
  end
end