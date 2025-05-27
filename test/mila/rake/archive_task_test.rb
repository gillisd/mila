# require 'minitest/autorun'
# require 'rubygems/package'
# require 'zlib'
# require_relative '../archive_task'
# require_relative 'support/assertions'
# require_relative 'support/env'

require 'test_helper'

module Rake
  class ArchiveTaskTest < Minitest::Test
    include Support::AppleArchive::Helpers

    attr_reader :env

    include Support::Assertions

    ArchiveTask = Mila::Rake::ArchiveTask

    def setup
      @env = Support::Rake::Env.new(binding)
      @env.mkdir_p 'src'
      @env.mkdir_p 'dest'
      @env.start
    end

    def teardown
      env.stop
    end

    def test_tar_gz
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')

      ArchiveTask.new(:archive_files) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar.gz')
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_files)
      path = env.path_for('dest/archive.tar.gz')

      assert_path_exists path

      io = Zlib::GzipReader.wrap(path.open)
      reader = Gem::Package::TarReader.new(io)
      names = reader.map(&:full_name)
      assert_pattern { names => ['./src/file1.txt', './src/file2.rb'] }
    end

    def test_tar
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')
      env.touch_file('src/.conf', 'puts "Hello World"')

      ArchiveTask.new(:archive_files) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar')
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_files)
      path = env.path_for('dest/archive.tar')

      assert_path_exists path

      reader = Gem::Package::TarReader.new(path.open)
      names = reader.map(&:full_name)
      # names
      assert_pattern { names => ['./src/file1.txt', './src/.conf', './src/file2.rb'] }
    end

    def test_zip
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')

      ArchiveTask.new(:archive_files) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.zip')
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_files)
      path = env.path_for('dest/archive.zip')

      assert_path_exists path

      Zip::File.open(path) do |zip_file|
        entries = zip_file.map(&:name)
        assert_pattern { entries => ['src/', 'src/file1.txt', 'src/file2.rb'] }
      end
    end

    def test_apple_archive
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')

      ArchiveTask.new(:archive_files) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.aarchive')
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_files)
      path = env.path_for('dest/archive.aarchive')

      with_apple_archive path do
        assert_archive_contains 'src/file1.txt'
        assert_archive_contains 'src/file2.rb'
      end

      # contents = Support::AppleArchive.list_archive_files path
      #
      # assert_path_exists path
      # assert_pattern { contents.to_a => ['src/file1.txt', 'src/file2.rb'] }
    end
  end
end