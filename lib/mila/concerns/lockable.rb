module Mila
  module Lockable

    DEFAULT_ERROR_MESSAGE = 'This writer is no longer available as it has been explicitly locked'

    LockedWriterError = Class.new StandardError

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def lock_writer(attribute, on: :lock_writer!, message: DEFAULT_ERROR_MESSAGE)
        lock_writers(attribute, on: on, message: message)
      end

      def lock_writers(*attributes, on: :lock_writers!, message: DEFAULT_ERROR_MESSAGE)
        locking_module = Module.new do |m|
          attributes.each do |attribute|
            m.define_method "#{attribute.to_s}=".to_sym do |*_|
              raise Lockable::LockedWriterError.new("#{message}: #{attribute.to_s}")
            end
          end
        end

        method_exists = method_defined?(on) || private_method_defined?(on)
        helper_module = Module.new do |m|
          m.define_method on do |*_|
            super if method_exists
            singleton_class.prepend locking_module
          end
        end
        # Must add the lock! helper methods inside of a module so that super will work properly if they
        # are overridden.
        include helper_module
      end
    end
  end
end