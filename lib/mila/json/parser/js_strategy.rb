module Mila
  module JSON
    class Parser::JsStrategy
      def self.default_source
        <<~JS
          function parseJson(string) {
             return JSON.parse(string);
           }
           
           function dumpJson(object) {
              return JSON.stringify(object);
             } 
        JS
      end

      def initialize(source = self.class.default_source)
        @context = ExecJS.runtime.compile(source)
      end

      def parse(json_string)
        @context.call('parseJson', json_string)
      end
    end
  end
end