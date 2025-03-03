module Mila
  module Benchmark
    module Mixin

      module JS
        module Body
          class Inline
            def initialize(body = '')
              @body = body
            end

            def open(&block)
              @body = block.call
            end

            def entrypoint_name
              raise 'Cannot call entrypoint_name on inline code'
            end

            def load
              @body
            end
          end
        end
      end

      class V8Session
        def initialize
          @queue = Queue.new
          @thread = Thread.new { create_context }
          @body = nil
          @has_source = false
        end

        def context
          @context ||= @queue.pop
        end

        def eval_inline(&block)
          @body = JS::Body::Inline.new
          @body.open(&block)
          add_source(@body)
        end

        def load_bundleable_lib(lib)
          raise ArgumentError if lib.nil?

          @body = JS::Body::Library.new(lib)
          add_source(@body)
        end

        def call(*args)
          case args
          in [function_name, args_array]
            function_name = function_name.to_s
          in [args_array]
            function_name = @body.entrypoint_name
          else
            raise ArgumentError, 'Invalid arguments'
          end
          context.call(function_name, args_array)
        end

        private

        def add_source(body)
          raise ArgumentError, 'Cannot add source to a session with a body' if @has_source

          context.eval(body.load)
        end

        def create_context
          @queue << MiniRacer::Context.new
        end
      end

      def benchmark(label = 'benchmark', &block)
        param_count = block.arity

        if param_count == 0
          return simple_benchmark(label, &block)
        end

        reporter_benchmark(&block)
      end

      def ips(time = 5, warmup = 2, quiet = false, &block)
        puts build_header(block)
        require 'benchmark/ips'
        ::Benchmark.ips(time: time, warmup: warmup, quiet: quiet) do |job|
          proxy = ReporterProxy.new(job)
          block.call(proxy)
          job.compare!
        end
      end

      private

      def reporter_benchmark(&block)
        benchmark_results = nil
        enum = Enumerator.new do |y|
          benchmark_results = ::Benchmark.bm do |reporter|
            proxy = ReporterProxy.new(reporter, yielder: y)
            block.call(proxy)
          end
        end

        print build_header(block)
        enum.count #eager load the enum
        puts benchmark_results
        enum.rewind
        enum
      end

      def build_header(block)
        source_location = block.binding.source_location
        file = source_location[0]
        line = source_location[1]
        "Benchmarking #{file}:#{line}"
      end

      def simple_benchmark(label, &block)
        result = nil
        time = ::Benchmark.measure(label) do
          result = block.call
        end
        puts time
        result
      end
    end
  end
end