module Mila
  module Minitest
    module Retryable
      class Retrier
        attr_reader :test

        # @!attribute [r] test
        def initialize(test)
          @test = test
          @retrying = false
          @original_failures = nil
          @original_assertions = nil
        end

        def try_retrying
          return false unless retryable?
          prep_retries
          begin
            max_attempts.times do |n|
              puts "#{test.location} failed. Retrying. Attempt #{n + 1} of #{max_attempts}"

              test.failures.clear
              test.assertions = 0
              @retrying = true
              test.run
              if test.failures.any?
                next
              else
                break
              end
            end
          ensure
            finish
          end
        end

        def prep_retries
          @original_failures = test.failures.dup
          @original_assertions = test.assertions
        end

        def retryable?
          return false unless retry_specification
          !(@retrying || test.passed?)
        end

        def finish
          @retrying = false
          return if test.passed?

          # give back the original first attempt failure(s) as backtrace does not include anything in here
          test.failures = @original_failures
          test.assertions = @original_assertions
        end

        def retry_specification
          test.retry_specification
        end

        def max_attempts
          retry_specification.max_retry_count
        end
      end
    end
  end
end
