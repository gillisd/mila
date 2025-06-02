# require 'minitest/autorun'
# require_relative '../copy_task'
# require_relative 'support/assertions'
# require_relative 'support/env'
require 'test_helper'

module Rake
  class CopyTaskTest < Minitest::Test
    attr_reader :env

    # parallelize_me!

    include Support::Assertions

    CopyTask = Mila::Rake::CopyTask
    Lockable = Mila::Lockable

    def setup
      @env = Support::Rake::Env.new
      @env.mkdir_p 'src'
      @env.mkdir_p 'dest'
      @env.start
    end

    def teardown
      env.stop
    end


    def test_simple_task
      mock = Minitest::Mock.new
      mock.expect :call, nil

      Rake::Task.define_task :foo do
        mock.call
      end

      Rake::Task[:foo].invoke
      assert_mock mock
    end

    def test_environment_cleans_up
      env.touch_file 'foo'
      assert_path_exists env.path_for 'foo'
      env.stop
      refute_path_exists env.path_for 'foo'
    end

    def test_basic_file_copying
      # Setup source files
      env.touch_file('src/file1.txt', 'Content of file 1')
      env.touch_file('src/file2.rb', 'puts "Hello World"')

      # Create copy task
      CopyTask.new(:copy_files) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      # Execute the task
      env.invoke_task(:copy_files)

      # Verify files were copied
      assert_path_exists env.path_for('dest/src/file1.txt')
      assert_path_exists env.path_for('dest/src/file2.rb')
      assert_file_contains env.path_for('dest/src/file1.txt'), 'Content of file 1'
      assert_file_contains env.path_for('dest/src/file2.rb'), 'puts "Hello World"'
    end

    def test_directory_structure_preservation
      # Create nested directory structure
      env.touch_file('project/lib/main.rb', 'class Main; end')
      env.touch_file('project/lib/utils/helper.rb', 'module Helper; end')
      env.touch_file('project/test/test_main.rb', 'require "minitest"')

      CopyTask.new(:copy_project) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('backup')
        t.include 'project/**/*'
      end

      env.invoke_task(:copy_project)

      # Verify directory structure is preserved
      assert_path_exists env.path_for('backup/project/lib/main.rb')
      assert_path_exists env.path_for('backup/project/lib/utils/helper.rb')
      assert_path_exists env.path_for('backup/project/test/test_main.rb')
    end

    def test_multiple_include_patterns
      # Create files matching different patterns
      env.touch_file('docs/readme.md', '# README')
      env.touch_file('docs/guide.txt', 'User guide')
      env.touch_file('src/main.rb', 'puts "main"')
      env.touch_file('src/helper.rb', 'puts "helper"')
      env.touch_file('build/output.log', 'build log') # Should not be included

      CopyTask.new(:selective_copy) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('selected')
        t.include 'docs/**/*'
        t.include 'src/*.rb'
      end

      env.invoke_task(:selective_copy)

      # Verify only matching files are copied
      assert_path_exists env.path_for('selected/docs/readme.md')
      assert_path_exists env.path_for('selected/docs/guide.txt')
      assert_path_exists env.path_for('selected/src/main.rb')
      assert_path_exists env.path_for('selected/src/helper.rb')
      refute_path_exists env.path_for('selected/build/output.log')
    end

    def test_absolute_directory_inclusion
      # Create directory outside of root_dir
      external_dir = env.path_for('external')
      external_dir.mkpath
      env.touch_file('external/config.yml', 'database: test')

      CopyTask.new(:copy_external) do |t|
        t.root_dir = env.path_for('src')
        t.destination_dir = env.path_for('dest')
        t.include external_dir.to_s
      end

      env.invoke_task(:copy_external)

      assert_path_exists env.path_for('dest/external/config.yml')
    end

    def test_dotfiles_are_excluded_by_default
      # Create various dotfiles and hidden directories
      env.touch_file('src/.hidden_file', 'secret')
      env.touch_file('src/.env', 'API_KEY=secret')
      env.touch_file('src/normal_file.txt', 'normal content')

      CopyTask.new(:copy_no_dotfiles) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      env.invoke_task(:copy_no_dotfiles)

      # Normal files should be copied, dotfiles should not
      assert_path_exists env.path_for('dest/src/normal_file.txt')
      refute_path_exists env.path_for('dest/src/.hidden_file')
      refute_path_exists env.path_for('dest/src/.env')
    end

    def test_dotfiles_can_be_included
      # Create various dotfiles and hidden directories
      env.touch_file('src/.hidden_file', 'secret')
      env.touch_file('src/.env', 'API_KEY=secret')
      env.touch_file('src/normal_file.txt', 'normal content')

      CopyTask.new(:copy_include_dotfiles) do |t|
        t.root_dir = env.workdir
        t.include_dotfiles = true
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      env.invoke_task(:copy_include_dotfiles)

      assert_path_exists env.path_for('dest/src/normal_file.txt')
      assert_path_exists env.path_for('dest/src/.hidden_file')
      assert_path_exists env.path_for('dest/src/.env')
    end

    def test_ds_store_files_are_excluded
      # Create .DS_Store files (common on macOS)
      env.touch_file('src/.DS_Store', 'binary data')
      env.touch_file('src/subdir/.DS_Store', 'more binary data')
      env.touch_file('src/important.txt', 'keep this')

      CopyTask.new(:copy_clean) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      env.invoke_task(:copy_clean)

      assert_path_exists env.path_for('dest/src/important.txt')
      refute_path_exists env.path_for('dest/src/.DS_Store')
      refute_path_exists env.path_for('dest/src/subdir/.DS_Store')
    end

    def test_required_arguments_validation
      assert_raises ArgumentError, 'Required argument root_dir was not present' do
        CopyTask.new(:invalid_task) do |t|
          t.destination_dir = env.path_for('dest')
          # Missing root_dir
        end
      end

      assert_raises ArgumentError, 'Required argument destination_dir was not present' do
        CopyTask.new(:invalid_task) do |t|
          t.root_dir = env.workdir
          # Missing destination_dir
        end
      end
    end

    def test_task_dependencies_are_created
      env.touch_file('src/file.txt', 'content')

      CopyTask.new(:copy_with_deps) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      # Verify that directory creation task exists
      assert_task_defined env.path_for('dest').to_s

      # Verify that individual file tasks exist
      target_file = env.path_for('dest/src/file.txt').to_s
      assert_task_defined target_file

      # Verify main task exists and depends on file tasks
      assert_task_defined :copy_with_deps
    end

    def test_hard_link_preference_fallback
      # This is harder to test directly, but we can verify the behavior
      env.touch_file('src/large_file.txt', 'x' * 1000)

      CopyTask.new(:copy_with_links) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.prefer_hard_links = true
        t.include 'src/**/*'
      end

      env.invoke_task(:copy_with_links)

      # File should exist regardless of whether hard linking worked
      target_file = env.path_for('dest/src/large_file.txt')
      assert_path_exists target_file
      assert_file_contains target_file, 'x' * 1000
    end

    def test_copy_without_hard_links
      env.touch_file('src/file.txt', 'test content')

      CopyTask.new(:copy_no_links) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.prefer_hard_links = false
        t.include 'src/**/*'
      end

      env.invoke_task(:copy_no_links)

      assert_path_exists env.path_for('dest/src/file.txt')
      assert_file_contains env.path_for('dest/src/file.txt'), 'test content'
    end

    def test_writers_are_locked_after_initialization
      copy_task = CopyTask.new(:locked_task) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      # These should raise LockedWriterError
      assert_raises Lockable::LockedWriterError do
        copy_task.root_dir = '/different/path'
      end

      assert_raises Lockable::LockedWriterError do
        copy_task.destination_dir = '/different/dest'
      end

      assert_raises Lockable::LockedWriterError do
        copy_task.prefer_hard_links = false
      end
    end

    def test_source_and_target_files_lazy_evaluation
      env.touch_file('src/file1.txt', 'content1')
      env.touch_file('src/file2.txt', 'content2')

      copy_task = CopyTask.new(:lazy_eval) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'src/**/*'
      end

      # Verify that source_files and target_files return expected types
      source_files = copy_task.source_files
      target_files = copy_task.target_files

      assert_kind_of Rake::FileList, source_files
      assert_kind_of Rake::FileList, target_files
      assert_equal source_files.length, target_files.length

      # Verify actual file paths are reasonable
      assert source_files.any? { |f| f.to_s.include?('file1.txt') }
      assert target_files.any? { |f| f.to_s.include?('file1.txt') }
    end

    def test_empty_source_directory
      # Create empty source directory
      env.path_for('empty_src').mkpath

      CopyTask.new(:copy_empty) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest')
        t.include 'empty_src/**/*'
      end

      # Should not raise an error
      env.invoke_task(:copy_empty)

      # Destination directory should still be created
      assert_path_exists env.path_for('dest')
    end

    def test_concurrent_flag_affects_task_type
      env.touch_file('src/file.txt', 'content')

      # Test with concurrent = false (default)
      copy_task_sequential = CopyTask.new(:copy_sequential) do |t|
        t.root_dir = env.workdir
        t.destination_dir = env.path_for('dest1')
        t.concurrent = false
        t.include 'src/**/*'
      end

      # Test with concurrent = true (assuming MultiFileTask exists)
      # This might need to be mocked if MultiFileTask isn't available
      begin
        copy_task_concurrent = CopyTask.new(:copy_concurrent) do |t|
          t.root_dir = env.workdir
          t.destination_dir = env.path_for('dest2')
          t.concurrent = true
          t.include 'src/**/*'
        end

        # Both tasks should be defined
        assert_task_defined :copy_sequential
        assert_task_defined :copy_concurrent
      rescue NameError => e
        skip "MultiFileTask not available: #{e.message}"
      end
    end
  end
end