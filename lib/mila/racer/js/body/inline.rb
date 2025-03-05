module Racer
  module JS
    module Body
      class Inline
        def initialize(body = '')
          @body = body
        end

        def open(&block)
          @body = block.call
        end

        def entrypoint_name
          raise 'Cannot call entrypoint_name on inline code'
        end

        def load
          @body
        end
      end
    end
  end
end