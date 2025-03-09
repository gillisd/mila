module Mila
  module Refinements
    module Pathname
      refine Pathname do
        def to_pathname
          self
        end
      end
    end
  end
end
