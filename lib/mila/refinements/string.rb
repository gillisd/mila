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

        def to_h
          Mila::JSON.parse(self)
        end

        def increment_version
          components = split('.')
          components[-1] = (components[-1].to_i + 1).to_s
          components.join('.')
        end
      end
    end
  end
end