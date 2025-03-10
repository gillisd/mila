module Mila
  module Refinements
    module JSON
      refine ::String do
        def to_h
          Mila::JSON.parse(self)
        end
      end
    end
  end
end