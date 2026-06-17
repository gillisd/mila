require 'rake'

module Support
  class RakeEnv
    METHOD_MAP = ::Rake.singleton_methods.inject({}) do |hash, rake_method_name|
      prock_method = ::Rake.singleton_method(rake_method_name).to_proc rescue nil

      next(hash) if prock_method.nil?
      hash.merge(rake_method_name => prock_method)
    end

    rake_method_mixin = Module.new
    METHOD_MAP.each do |name, prock|
      rake_method_mixin.define_method(name, &prock)
    end

    include rake_method_mixin

    # def application
    #   @application ||= ::Rake::Application.new
    # end

    # def method_missing(name, *args, **kwargs, &block)
    #   if application.respond_to? name
    #     application.send(name, *args, **kwargs, &block)
    #   else
    #     super
    #   end
    # end
    # def self.included(base)
    # base.attr_reader :env
    # mod = Module.new do |m|
    #   m.define_method :included do |b|
    #   end

    # m.define_method :before_setup do
    #   @env = Support::Rake::Env.new
    #   @env.mkdir_p 'src'
    #   @env.mkdir_p 'dest'
    #   @env.start
    # end
    #
    # m.define_method :after_teardown do
    #   @env.stop
    # end
    # end
    # base.include mod
    # end
  end
end