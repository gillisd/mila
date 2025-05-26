module Mila

  module Minitest
    module Retryable
      module ClassMethods

        def retry_specifications
          @retry_specifications
        end

        def pending_retry_specification
          @pending_retry_specification
        end

        def retries(retry_enum)
          if @pending_retry_specification
            raise "Cannot define more than one retry specification above a given method"
          end

          @pending_retry_specification = Mila::Minitest::Retryable::RetrySpecification.new(retry_enum)
        end

        def method_added(method)
          super
          return unless pending_retry_specification
          create_retry_specification(method)
        end

        def create_retry_specification(method)
          pending_retry_specification.finalize(method)
          pending_retry_specification.validate!
          @retry_specifications << pending_retry_specification
          @pending_retry_specification = nil
        end
      end

      def self.included(base)
        base.singleton_class.alias_method :__inherited_retryable, :inherited
        base.define_singleton_method :inherited do |subclass|
          __inherited_retryable(subclass)
          return if subclass == ::Minitest::Spec
          subclass.instance_variable_set :@retry_specifications, []
          subclass.instance_variable_set :@pending_retry_specification, nil
          base.extend(ClassMethods)
        end
      end

      def try_to_retry
        @retrier ||= Mila::Minitest::Retryable::Retrier.new(self)
        @retrier.try_retrying
      end

      def retry_specification
        self.class.retry_specifications.find { _1.valid_for_test?(self) }
      end

      def after_teardown
        try_to_retry unless passed?
        super
      end
    end
  end
end

