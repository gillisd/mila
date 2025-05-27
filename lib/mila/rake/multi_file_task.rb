# A concurrent version of FileTask, using same pattern as MultiTask
module Mila
  module Rake
    class MultiFileTask < ::Rake::FileTask
      private

      def invoke_prerequisites(task_args, invocation_chain)
        # :nodoc:
        invoke_prerequisites_concurrently(task_args, invocation_chain)
      end
    end
  end
end