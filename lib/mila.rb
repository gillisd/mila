# frozen_string_literal: true

require 'bundler/setup'
require 'zeitwerk'

autoload :MiniRacer, 'mini_racer'
autoload :Benchmark, 'benchmark'
loader = Zeitwerk::Loader.for_gem
loader.setup

module Mila
  class Error < StandardError; end
end
