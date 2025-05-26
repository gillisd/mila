require 'minitest/autorun'

class RetryTest < Minitest::Test
  @retry_specifications = []
  @pending_retry_specification = nil

  def self.retry_specifications
    @retry_specifications
  end

  def self.pending_retry_specification
    @pending_retry_specification
  end

  def self.retries(retry_enum)
    if @pending_retry_specification
      raise "Cannot define more than one retry specification above a given method"
    end

    @pending_retry_specification = RetrySpecification.new(retry_enum)
  end

  def self.method_added(method)
    super
    return unless pending_retry_specification
    create_retry_specification(method)
  end

  def self.create_retry_specification(method)
    pending_retry_specification.finalize(method)
    pending_retry_specification.validate!
    @retry_specifications << pending_retry_specification
    @pending_retry_specification = nil
  end

  def try_to_retry
    @retrier ||= Retrier.new(self)
    @retrier.try_retrying
  end

  def retry_specification
    self.class.retry_specifications.find { _1.valid_for_test?(self) }
  end

  def after_teardown
    try_to_retry unless passed?
  end

  @bars = [1, 2]

  def self.bar
    @bars.pop
  end

  def test_bar
    assert true
  end

  retries 1.times

  def test_foo

    result = self.class.bar
    assert result.nil?

    assert true

  end
end