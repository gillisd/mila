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

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect(
  'json' => 'JSON',
  'okjson' => 'OkJson'
)
multi_json_gem_dir = Gem.loaded_specs['multi_json'].full_gem_path
gem_lib = Pathname("#{multi_json_gem_dir}/lib")

loader.collapse('**/multi_json/vendor')
loader.push_dir(gem_lib, namespace: Object)
loader.ignore('lib/mila/racer/**/*')
loader.do_not_eager_load(gem_lib.join('multi_json', 'adapters'))
loader.setup

module Mila
  class Error < StandardError; end
end
