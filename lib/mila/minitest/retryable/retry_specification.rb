module Mila
  module Minitest
    module Retryable
      class RetrySpecification
        def initialize(enum, method_name: nil)
          @enum = enum
          @method_name = method_name
        end

        def pending?
          @method_name.nil?
        end

        def valid_for_test?(test)
          return false unless test.name == @method_name.to_s

          true
        end

        def validate!
          unless valid?
            raise "Invalid retry specification: #{@enum.inspect}"
          end
        end

        def valid?
          [@enum, @method_name] in [Enumerator, Symbol]
        end

        def finalize(method_name)
          @method_name = method_name
        end

        def max_retry_count
          @enum.count
        end

        def belongs_to_test?(method_name)
          begin
            instance_method(method_name)
          rescue NameError
            raise "Test name #{@method_name} not found"
          end
        end
      end
    end
  end
end