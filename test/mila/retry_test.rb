require 'minitest/autorun'

class Integer
  def retries_allowed

  end
end

class RetryTest < Minitest::Test
  @retries = []

  def self.retries
    @retries
  end

  def self.retryable(*args)
    retry_enum = args.first
    prock = lambda do |test|
      method_name_match = test.location.match(/^.*?#([^ ]+) \[/)

      return false unless method_name_match
      test_meth = method_name_match
                    .captures
                    .first
                    .to_sym
                    .then { instance_method _1 }

      raise "No test location found" if test_meth.nil?

      instance_methods.map { instance_method _1 }
                      .reject { _1.source_location.nil? }
                      .find { |method|
                        test_meth.source_location[1].to_i == method.source_location[1].to_i
                      }
    end
    @retries << [prock, retry_enum]
  end

  def retries_remaining(&block)
    _prock, enum = self.class
                       .retries
                       .find { |retry_proc, _enum| !!retry_proc.call(self) }
    enum.each(&block)
  end

  def after_teardown
    unless @retrying || passed?
      retries_remaining do |n|
        puts "#{self.location} failed. Retrying. Attempt #{n + 1} of #{retries_remaining.count}"
        __failures = failures.dup
        __assertions = assertions
        failures.clear
        self.assertions = 0
        @retrying = true
        run
        if self.failures.any?
          next
        else
          break
        end
      end
      @retrying = false
    end
  end

  @bars = [1, 2]

  def self.bar
    @bars.pop
  end

  retryable 2.times
  def test_bar
    assert true
  end


  def test_foo

    result = self.class.bar
    assert result.nil?

    assert true

  end
end