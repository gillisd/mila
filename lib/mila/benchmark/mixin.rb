module Mila
  module Benchmark
    module Mixin
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
        enum.count # eager load the enum
        puts benchmark_results
        enum.rewind
        enum
      end

      def simple_benchmark(label, &block)
        result = nil
        time = ::Benchmark.measure(label) do
          result = block.call
        end
        puts time
        result
      end

      def build_header(block)
        source_location = block.binding.source_location
        file = source_location[0]
        line = source_location[1]
        "Benchmarking #{file}:#{line}"
      end
    end
  end
end