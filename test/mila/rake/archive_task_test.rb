# require 'minitest/autorun'
# require 'rubygems/package'
# require 'zlib'
# require_relative '../archive_task'
# require_relative 'support/assertions'
# require_relative 'support/env'

require 'test_helper'

module Rake
  # class ArchiveTaskTest < Minitest::Test
  #
  #   attr_reader :env
  #
  #   include Support::Assertions
  #
  #   ArchiveTask = Mila::Rake::ArchiveTask
  #
  #   def setup
  #     @env = Support::Rake::Env.new(binding)
  #     @env.mkdir_p 'src'
  #     @env.mkdir_p 'dest'
  #     @env.start
  #   end
  #
  #   def teardown
  #     env.stop
  #   end
  #
  #   def test_tar_gz
  #     env.touch_file('src/file1.txt', 'Content of file 1')
  #     env.touch_file('src/file2.rb', 'puts "Hello World"')
  #
  #     ArchiveTask.new(:archive_files) do |t|
  #       t.root_dir = env.workdir
  #       t.destination_path = env.path_for('dest/archive.tar.gz')
  #       t.include 'src/**/*'
  #     end
  #
  #     env.invoke_task(:archive_files)
  #     path = env.path_for('dest/archive.tar.gz')
  #
  #     assert_path_exists path
  #
  #     io = Zlib::GzipReader.wrap(path.open)
  #     reader = Gem::Package::TarReader.new(io)
  #     names = reader.map(&:full_name)
  #     assert_pattern { names => ['./src/file1.txt', './src/file2.rb'] }
  #   end
  #
  #   def test_zip
  #     env.touch_file('src/file1.txt', 'Content of file 1')
  #     env.touch_file('src/file2.rb', 'puts "Hello World"')
  #
  #     ArchiveTask.new(:archive_files) do |t|
  #       t.root_dir = env.workdir
  #       t.destination_path = env.path_for('dest/archive.zip')
  #       t.include 'src/**/*'
  #     end
  #
  #     env.invoke_task(:archive_files)
  #     path = env.path_for('dest/archive.zip')
  #
  #     assert_path_exists path
  #
  #     Zip::File.open(path) do |zip_file|
  #       entries = zip_file.map(&:name)
  #       assert_pattern { entries => ['src/', 'src/file1.txt', 'src/file2.rb'] }
  #     end
  #   end
  #
  # end
  def test_does_not_include_staging_files

  end

  class TarArchiveTest < Minitest::Test
    include Support::Rake
    include Support::TarArchive

    ArchiveTask = Mila::Rake::ArchiveTask

    def test_tar
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')
      env.touch_file('src/conf', 'puts "Hello World"')

      ArchiveTask.new(:archive_files) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar')
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_files)
      path = env.path_for('dest/archive.tar')

      assert_path_exists path

      assert_archive_contains(path, './src/file1.txt')
      assert_archive_contains(path, './src/file2.rb')
      assert_archive_contains(path, './src/conf')
    end

    def test_tar_gz
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')
      env.touch_file('src/conf', 'puts "Hello World"')

      ArchiveTask.new(:archive_files_gz) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar.gz')
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_files_gz)
      path = env.path_for('dest/archive.tar.gz')

      assert_path_exists path

      assert_compressed_archive_contains(path, './src/file1.txt')
      assert_compressed_archive_contains(path,'./src/file2.rb')
      assert_compressed_archive_contains(path, './src/conf')
    end

    def test_tar_with_include_dotfiles_false
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')
      env.touch_file('src/.hidden_file', 'secret content')
      env.touch_file('src/.env', 'API_KEY=secret')

      ArchiveTask.new(:archive_no_dotfiles) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar')
        t.include_dotfiles = false
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_no_dotfiles)
      path = env.path_for('dest/archive.tar')

      assert_path_exists path

      # Regular files should be included
      assert_archive_contains(path, './src/file1.txt')
      assert_archive_contains(path, './src/file2.rb')

      # Dotfiles should be excluded
      refute_archive_contains(path, './src/.hidden_file')
      refute_archive_contains(path, './src/.env')
    end

    def test_tar_with_include_dotfiles_true
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')
      env.touch_file('src/.hidden_file', 'secret content')
      env.touch_file('src/.env', 'API_KEY=secret')

      ArchiveTask.new(:archive_with_dotfiles) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar')
        t.include_dotfiles = true
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_with_dotfiles)
      path = env.path_for('dest/archive.tar')

      assert_path_exists path

      # Regular files should be included
      assert_archive_contains(path, './src/file1.txt')
      assert_archive_contains(path, './src/file2.rb')

      # Dotfiles should also be included
      assert_archive_contains(path, './src/.hidden_file')
      assert_archive_contains(path, './src/.env')
    end

    def test_tar_gz_with_include_dotfiles_false
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/.hidden_file', 'secret content')

      ArchiveTask.new(:archive_gz_no_dotfiles) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar.gz')
        t.include_dotfiles = false
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_gz_no_dotfiles)
      path = env.path_for('dest/archive.tar.gz')

      assert_path_exists path

      # Regular files should be included
      assert_compressed_archive_contains(path, './src/file1.txt')

      # Dotfiles should be excluded
      refute_compressed_archive_contains(path, './src/.hidden_file')
    end

    def test_tar_gz_with_include_dotfiles_true
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/.hidden_file', 'secret content')

      ArchiveTask.new(:archive_gz_with_dotfiles) do |t|
        t.root_dir = env.workdir
        t.destination_path = env.path_for('dest/archive.tar.gz')
        t.include_dotfiles = true
        t.include 'src/**/*'
      end

      env.invoke_task(:archive_gz_with_dotfiles)
      path = env.path_for('dest/archive.tar.gz')

      assert_path_exists path

      # Regular files should be included
      assert_compressed_archive_contains(path, './src/file1.txt')

      # Dotfiles should also be included
      assert_compressed_archive_contains(path, './src/.hidden_file')
    end
  end

  class AppleArchiveTest < Minitest::Test
    include Support::Rake
    include Support::AppleArchive

    ArchiveTask = Mila::Rake::ArchiveTask

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

      assert_path_exists path

      assert_archive_contains(path, 'src/file1.txt')
      assert_archive_contains(path, 'src/file2.rb')
    end
  end
end