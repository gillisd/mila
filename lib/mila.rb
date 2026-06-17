# frozen_string_literal: true

require 'pathname'
require 'zeitwerk'
require 'uri'

autoload :MiniRacer, 'mini_racer'
autoload :Benchmark, 'benchmark'
autoload :ExecJS, 'execjs'
autoload :Singleton, 'singleton'
autoload :Zlib, 'zlib'
autoload :JSON, 'json'
autoload :Oj, 'oj'
autoload :SimpleDelegator, 'delegate'
autoload :Shellwords, 'shellwords'

module Gem
  autoload :Package, 'rubygems/package'
  autoload :Installer, 'rubygems/installer'
end

module Rake
  autoload :TaskLib, 'rake/tasklib'
  autoload :FileList, 'rake/file_list'
  autoload :MultiTask, 'rake/multi_task'
end

module RDoc
  autoload :RubyGemsHook, 'rdoc/rubygems_hook'
end

class Loader < Zeitwerk::Loader
  # def initialize
  #   super
  #   namespace = Object
  #   self.tag = namespace.name + '-' + File.basename(__FILE__, '.rb')
  #   self.inflector = Zeitwerk::GemInflector.new(__FILE__)
  #   push_dir(__dir__, namespace: namespace)
  # end

  def autoload_gem(gem_name, &block)
    gem_name = gem_name.to_s
    gem = Gem.loaded_specs
             .fetch(gem_name, nil)
    raise LoadError, "gem #{gem_name} not found" unless gem

    push_dir gem.full_gem_path

    block.call(gem) if block_given?
  end
end

# these globs are problematic
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

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect(
  'json' => 'JSON',
  'okjson' => 'OkJson',
  'enhanced_rubygems_hook' => 'EnhancedRubyGemsHook',
  'rdoc' => 'RDoc'
)

root = Pathname(__dir__.to_s)
loader.ignore(root.join('mila/racer/**/*'))
loader.ignore(root.join('minitest/**/*'))
loader.collapse(root.join('mila/concerns'))
loader.setup
$loader = loader

module Mila
  extend self

  def root
    Pathname(__dir__.to_s)
  end

  class Error < StandardError; end
end
