# frozen_string_literal: true

require 'tempfile'
require 'pathname'
require_relative 'lib/mila/version'
require_relative 'lib/mila/refinements/string'
require "minitest/test_task"
require "bundler/gem_tasks"

using Mila::Refinements::String

Minitest::TestTask.create

root_path = __dir__.to_pathname
lib_path = root_path.join('lib')
project_path = lib_path.join('mila')

namespace :version do
  version_path = project_path.join('version.rb')
  file version_path
  task :bump => [version_path] do
    version_path.open(File::RDWR | File::CREAT, 0644) do |f|
      f.flock(File::LOCK_EX)
      current_version = Mila::VERSION
      source = f.read

      begin
        next_version = current_version.increment_version
        source.gsub!(current_version, next_version)
        f.rewind
        f.write(source)
      rescue => e
        f.rewind
        f.write(source)
        raise e
      end
    end
  end
end

task default: :test
