module Mila
  module JSON
    class Parser
      def initialize(parser = :default)
        @strategy = StrategyProvider.instance.parser_strategy(parser)
      end

      def parse(json_string, format: :symbol)
        @strategy.parse(json_string, format: format)
      end
    end
  end
end