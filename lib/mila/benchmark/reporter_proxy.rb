module Mila
  module Benchmark
    class ReporterProxy < SimpleDelegator
      def initialize(obj, yielder: nil)
        super(obj)
        @count = 1
        @yielder = yielder
      end

      def report(name = "trial #{@count}", &block)
        __getobj__.report(name) do
          begin
            result = block.call
            @yielder << result if @yielder
          rescue => e
            real_backtrace = e.backtrace.reject { |line| line =~ /lib\/mila/ }
            e.set_backtrace(real_backtrace)
            raise e
          end
        end
        @count += 1
      end

      alias r report
    end
  end
end
