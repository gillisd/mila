module Racer
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
end