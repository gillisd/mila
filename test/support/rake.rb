module Support
  module Rake
    def self.included(base)
      base.attr_reader :env
      mod = Module.new do |m|
        m.define_method :included do |b|
        end

        m.define_method :before_setup do
          @env = Support::Rake::Env.new(binding)
          @env.mkdir_p 'src'
          @env.mkdir_p 'dest'
          @env.start
        end

        m.define_method :after_teardown do
          @env.stop
        end
      end
      base.include mod
    end
  end
end