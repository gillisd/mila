module Mila
  module Refinements
    module String
      refine ::String do
        def camelize
          split('_').map(&:capitalize).join
        end

        def underscore
          gsub(/([a-z])([A-Z])/, '\1_\2').downcase
        end

        def dasherize
          gsub(/_/, '-')
        end

        def titleize
          split('_').map(&:capitalize).join(' ')
        end

        def to_pathname
          ::Pathname.new(self)
        end
      end
    end
  end
end