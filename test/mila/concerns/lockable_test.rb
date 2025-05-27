require 'minitest/autorun'
require_relative '../lockable'

class LockableTest < Minitest::Test
  attr_reader :subject

  class TestLockWriterClass
    include Lockable

    attr_accessor :color
    attr_accessor :size, :age, :brightness
    attr_accessor :name, :description

    lock_writer :color, on: :lock_color!
    lock_writers :size, :age, :brightness, on: :lock_three!
    lock_writer :name, on: :lock_name!, message: 'Custom error: name is locked'
    lock_writer :description, on: :lock_with_return!

    def lock_with_return!
      super
      "locked successfully"
    end
  end

  class InheritedTestClass < TestLockWriterClass
    attr_accessor :weight

    lock_writer :weight, on: :lock_weight!

    def lock_color!
      @custom_lock_called = true
      super
    end

    def custom_lock_called?
      @custom_lock_called || false
    end
  end

  def setup
    @subject = TestLockWriterClass.new
  end

  # Original tests
  def test_can_access_before_lock
    subject.color = 'blue'
    assert_equal 'blue', subject.color
  end

  def test_can_read_after_lock
    subject.color = 'red'
    assert_equal 'red', subject.color
    subject.lock_color!
    assert_equal 'red', subject.color
  end

  def test_cannot_write_after_lock
    subject.color = 'red'
    assert_equal 'red', subject.color
    subject.lock_color!
    assert_raises Lockable::LockedWriterError do
      subject.color = 'green'
    end
  end

  def test_can_lock_multiple_writers
    subject.size = 10
    subject.age = 5
    subject.brightness = 100

    assert_equal 10, subject.size
    assert_equal 5, subject.age
    assert_equal 100, subject.brightness

    subject.lock_three!

    assert_equal 10, subject.size
    assert_equal 5, subject.age
    assert_equal 100, subject.brightness

    assert_raises Lockable::LockedWriterError do
      subject.size = 20
    end

    assert_raises Lockable::LockedWriterError do
      subject.age = 10
    end

    assert_raises Lockable::LockedWriterError do
      subject.brightness = 200
    end
  end

  # New suggested tests
  def test_lock_method_can_be_called_multiple_times
    subject.color = 'blue'
    subject.lock_color!
    subject.lock_color! # Should not raise error

    # Should still be locked
    assert_raises Lockable::LockedWriterError do
      subject.color = 'green'
    end

    # Should still be readable
    assert_equal 'blue', subject.color
  end

  def test_custom_error_messages
    subject.name = 'John'
    subject.lock_name!

    error = assert_raises Lockable::LockedWriterError do
      subject.name = 'Jane'
    end

    assert_equal 'Custom error: name is locked: name', error.message
  end

  def test_inheritance_behavior
    inherited_subject = InheritedTestClass.new

    # Test inherited lock behavior
    inherited_subject.color = 'red'
    inherited_subject.lock_color!

    assert inherited_subject.custom_lock_called?

    assert_raises Lockable::LockedWriterError do
      inherited_subject.color = 'blue'
    end

    # Test new attribute in subclass
    inherited_subject.weight = 150
    inherited_subject.lock_weight!

    assert_raises Lockable::LockedWriterError do
      inherited_subject.weight = 160
    end
  end

  def test_method_chaining_and_return_values
    subject.description = "test"
    result = subject.lock_with_return!
    assert_equal "locked successfully", result

    assert_raises Lockable::LockedWriterError do
      subject.description = "changed"
    end
  end

  def test_lock_affects_only_specified_attributes
    subject.color = 'red'
    subject.size = 10
    subject.age = 5

    # Lock only color
    subject.lock_color!

    # Color should be locked
    assert_raises Lockable::LockedWriterError do
      subject.color = 'blue'
    end

    # Size and age should still be writable
    subject.size = 20
    subject.age = 10

    assert_equal 20, subject.size
    assert_equal 10, subject.age
  end

  def test_error_message_includes_attribute_name
    subject.color = 'red'
    subject.lock_color!

    error = assert_raises Lockable::LockedWriterError do
      subject.color = 'blue'
    end

    assert_includes error.message, 'color'
  end

  def test_multiple_lock_methods_on_same_attribute
    test_class = Class.new do
      include Lockable
      attr_accessor :value

      lock_writer :value, on: :lock_method_one!
      lock_writer :value, on: :lock_method_two!
    end

    instance = test_class.new
    instance.value = 'original'

    # Lock with first method
    instance.lock_method_one!

    assert_raises Lockable::LockedWriterError do
      instance.value = 'changed'
    end

    # Second lock method should still work (even though already locked)
    instance.lock_method_two!

    assert_raises Lockable::LockedWriterError do
      instance.value = 'changed_again'
    end
  end

  def test_lock_with_nil_values
    subject.color = nil
    subject.lock_color!

    # Should be able to read nil
    assert_nil subject.color

    # Should not be able to write even nil
    assert_raises Lockable::LockedWriterError do
      subject.color = nil
    end
  end

  def test_lock_preserves_original_method_behavior
    test_class = Class.new do
      include Lockable
      attr_reader :value

      def value=(new_value)
        @value = new_value.to_s.upcase
      end

      lock_writer :value, on: :lock_it!
    end

    instance = test_class.new
    instance.value = 'hello'
    assert_equal 'HELLO', instance.value

    instance.lock_it!
    assert_equal 'HELLO', instance.value

    assert_raises Lockable::LockedWriterError do
      instance.value = 'world'
    end
  end

  def test_lockable_error_is_standard_error
    assert_kind_of StandardError, Lockable::LockedWriterError.new
  end

  def test_default_error_message_constant
    assert_equal 'This writer is no longer available as it has been explicitly locked',
                 Lockable::DEFAULT_ERROR_MESSAGE
  end

  def test_lock_works_with_different_parameter_counts
    test_class = Class.new do
      include Lockable
      attr_accessor :value

      def value=(new_value, extra_param = nil)
        @value = new_value
        @extra = extra_param
      end

      lock_writer :value, on: :lock_it!
    end

    instance = test_class.new
    instance.value = 'test'
    instance.lock_it!

    assert_raises Lockable::LockedWriterError do
      instance.value = 'new_value', 'extra'
    end
  end
end