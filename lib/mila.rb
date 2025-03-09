# frozen_string_literal: true

require 'bundler/setup'
require 'zeitwerk'

autoload :MiniRacer, 'mini_racer'
autoload :Benchmark, 'benchmark'
autoload :Pathname, 'pathname'
autoload :ExecJS, 'execjs'
autoload :Singleton, 'singleton'
autoload :Zlib, 'zlib'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'json' => 'JSON'
)
loader.setup

module Mila
  class Error < StandardError; end
end
