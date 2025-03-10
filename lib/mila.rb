# frozen_string_literal: true

require 'bundler/setup'
require 'zeitwerk'

autoload :MiniRacer, 'mini_racer'
autoload :Benchmark, 'benchmark'
autoload :Pathname, 'pathname'
autoload :ExecJS, 'execjs'
autoload :Singleton, 'singleton'
autoload :Zlib, 'zlib'
autoload :JSON, 'json'
autoload :Oj, 'oj'
autoload :SimpleDelegator, 'delegate'

class Loader < Zeitwerk::Loader
  def initialize
    super
    namespace = Object
    self.tag = namespace.name + "-" + File.basename(__FILE__, ".rb")
    self.inflector = Zeitwerk::GemInflector.new(__FILE__)
    self.push_dir(__dir__, namespace: namespace)
  end

  def autoload_gem(gem_name, &block)
    gem_name = gem_name.to_s
    gem = Gem.loaded_specs
             .fetch(gem_name, nil)
    raise LoadError, "gem #{gem_name} not found" unless gem

    push_dir gem.full_gem_path

    block.call(gem) if block_given?
  end
end

# @param loader [Loader]
def load_multi_json(loader)
  loader.autoload_gem :multi_json do |gem|
    gem_pathname = Pathname(gem.full_gem_path)
    adapters_path = gem_pathname.join('multi_json/adapters')
    loader.collapse('**/multi_json/vendor')
    loader.do_not_eager_load(adapters_path.join('**/*'))
    loader.push_dir gem_pathname.join('lib')
  end
end

loader = Loader.new
loader.inflector.inflect(
  'json' => 'JSON',
  'okjson' => 'OkJson'
)
load_multi_json(loader)
loader.ignore('lib/mila/racer/**/*')
loader.setup

module Mila
  extend self

  def root
    Pathname(__dir__.to_s)
  end

  class Error < StandardError; end
end
