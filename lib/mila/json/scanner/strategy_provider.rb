module Mila
  module JSON
    class Scanner::StrategyProvider
      include Singleton

      def js_strategy
        @js_strategy ||= create_js_strategy
      end

      private

      def create_js_strategy
        Scanner::JsStrategy.new
      end
    end
  end
end