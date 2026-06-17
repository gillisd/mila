module Mila
  module JSON
    class String < SimpleDelegator
      def to_h(key_type: :symbol)
        ::JSON.parse(self, symbolize_names: key_type == :symbol)
      end
    end
  end
end