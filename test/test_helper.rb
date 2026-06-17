# frozen_string_literal: true

# ENV['MT_NO_PLUGINS'] = '1'
$LOAD_PATH.unshift File.expand_path('../lib', __dir__.to_s)

# require 'bundler/setup'
require 'pathname'
require 'zeitwerk'
require 'minitest/autorun'

autoload :Forwardable, 'forwardable'
autoload :SimpleDelegator, 'delegate'
autoload :DelegateClass, 'delegate'
autoload :Base64, 'base64'
autoload :Digest, 'digest'
autoload :SecureRandom, 'securerandom'
autoload :FileUtils, 'fileutils'
autoload :Rake, 'rake'

loader = Zeitwerk::Loader.new
loader.push_dir('test')
loader.ignore('**/*_test.rb')
loader.collapse('lib/mila/concerns/**/*')
loader.setup

test_dir = Pathname(__dir__.to_s)
lib_dir = test_dir.join('..', 'lib')
$LOAD_PATH.unshift(test_dir.realpath.to_s)
$LOAD_PATH.unshift(lib_dir.realpath.to_s)
require 'mila'
