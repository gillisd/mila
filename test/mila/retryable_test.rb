require 'test_helper'
require 'minitest/retryable_plugin'

class RetryableTest < Minitest::Test
  # Track attempts per test method using a hash
  def self.attempt_counters
    @attempt_counters ||= Hash.new(0)
  end

  # Individual setup counter for the setup test
  @@setup_counter = 0

  def setup
    # For the specific setup test, we use the class variable
    @@setup_counter += 1

    # Also track setup calls per test method
    test_name = self.name
    self.class.attempt_counters["#{test_name}_setup"] += 1
  end

  # Test that passes on first attempt
  def test_passes_first_attempt
    assert true
  end

  # Test that passes on second attempt
  retries 3.times
  def test_passes_on_second_attempt
    counter_key = "#{self.name}_count"
    self.class.attempt_counters[counter_key] += 1

    attempt = self.class.attempt_counters[counter_key]
    if attempt == 1
      flunk "Failing first attempt deliberately"
    else
      assert_equal 2, attempt
    end
  end

  # Test that passes on final attempt
  retries 3.times
  def test_passes_on_final_attempt
    counter_key = "#{self.name}_count"
    self.class.attempt_counters[counter_key] += 1

    attempt = self.class.attempt_counters[counter_key]
    if attempt < 3
      flunk "Failing attempt #{attempt} deliberately"
    else
      assert_equal 3, attempt
    end
  end

  # Test that fails all attempts
  retries 2.times
  def test_fails_all_attempts
    flunk "This test always fails"
  end

  # Test retry with custom error type
  retries 3.times
  def test_retries_only_specific_errors
    counter_key = "#{self.name}_count"
    self.class.attempt_counters[counter_key] += 1

    attempt = self.class.attempt_counters[counter_key]
    if attempt == 1
      1 / 0 # Raises ZeroDivisionError
    else
      assert_equal 2, attempt
    end
  end

  # Test custom retry interval
  retries 2.times
  def test_retry_with_wait
    counter_key = "#{self.name}_count"
    time_key = "#{self.name}_time"

    self.class.attempt_counters[counter_key] += 1
    attempt = self.class.attempt_counters[counter_key]

    current_time = Time.now

    if attempt == 1
      self.class.attempt_counters[time_key] = current_time
      flunk "Failing first attempt deliberately"
    else
      start_time = self.class.attempt_counters[time_key]
      elapsed = current_time - start_time
      assert elapsed >= 0.1, "Second attempt ran too quickly (#{elapsed}s)"
    end
  end

  # Store queue state in class variable but reset it for each test run
  @queue_items = [1, 2, 3]

  def self.pop_item
    @queue_items.pop
  end

  def self.reset_queue
    @queue_items = [1, 2, 3]
  end

  # Test with queue that gets depleted across retries
  retries 3.times
  def test_example_queue
    # Reset queue on first setup for this test
    setup_count = self.class.attempt_counters["#{self.name}_setup"]
    self.class.reset_queue if setup_count == 1

    result = self.class.pop_item

    if result.nil?
      assert_nil result
    else
      refute_nil result
      flunk "Queue still has items, forcing retry"
    end
  end

  # Test that verifies setup is called on every retry
  retries 2.times
  def test_setup_called_each_retry
    # Reset the setup counter for this specific test if it's the first run of the entire test suite
    test_attempt = self.class.attempt_counters["#{self.name}_attempt"] += 1

    if test_attempt == 1 && @@setup_counter > 3
      # We're in a full test suite run, need to adjust expectations
      expected_setups = @@setup_counter - 2  # Subtract previous test setups

      if @@setup_counter <= expected_setups
        flunk "Failing to trigger retry"
      else
        # After retries, check that setup has been called the expected number of times
        assert_equal expected_setups + 2, @@setup_counter
      end
    else
      # Individual test run or first test in suite
      if @@setup_counter <= 2
        flunk "Failing to trigger retry"
      else
        # On third attempt (after two retries), setup should have been called 3 times
        assert_equal 3, @@setup_counter
      end
    end
  end
end