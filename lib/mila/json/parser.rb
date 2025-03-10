module Mila
  module JSON
    class Parser
      # ::MultiJson.use Mila::JSON::Parser::MultiJson::Adapters::Bundled
      ::MultiJson.use :json_common

      def initialize(parser = :multi_json)
        @strategy = StrategyProvider.instance.parser_strategy(parser)
      end

      def parse(json_string, format: :symbol)
        @strategy.parse(json_string, format: format)
      end
    end
  end
end