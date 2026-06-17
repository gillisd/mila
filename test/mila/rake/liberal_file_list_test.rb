require 'minitest/autorun'
require 'rake'
require 'tempfile'
require 'fileutils'

# Assuming the LiberalFileList code is in a separate file
# require_relative 'liberal_file_list'

# If the code is inline, include it here:
module Rake
  class LiberalFileList < FileList
    def initialize(...)
      super

      clear_exclude
      exclude '.', '..'
    end

    def self.glob(pattern, *args)
      super(pattern, File::FNM_DOTMATCH, *args)
    end
  end
end

class LiberalFileListTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir

    # Create test files including hidden ones
    FileUtils.touch(File.join(@temp_dir, 'regular_file.txt'))
    FileUtils.touch(File.join(@temp_dir, '.hidden_file'))
    FileUtils.touch(File.join(@temp_dir, '.dotfile.rb'))
    FileUtils.touch(File.join(@temp_dir, 'another_file.rb'))

    # Create subdirectories
    FileUtils.mkdir_p(File.join(@temp_dir, 'subdir'))
    FileUtils.mkdir_p(File.join(@temp_dir, '.hidden_dir'))
    FileUtils.touch(File.join(@temp_dir, 'subdir', 'nested_file.txt'))
    FileUtils.touch(File.join(@temp_dir, '.hidden_dir', 'file_in_hidden.txt'))

    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  def test_initialize_clears_default_excludes
    file_list = Rake::LiberalFileList.new

    # Access the internal exclude patterns via instance variable
    # Should have no default ignore patterns, only '.' and '..'
    exclude_patterns = file_list.instance_variable_get(:@exclude_patterns)
    assert_equal ['.', '..'], exclude_patterns
  end

  def test_initialize_with_pattern
    file_list = Rake::LiberalFileList.new('*.txt')

    # Should include regular files
    assert_includes file_list.to_a, 'regular_file.txt'

    # Should exclude '.' and '..' only
    exclude_patterns = file_list.instance_variable_get(:@exclude_patterns)
    assert_equal ['.', '..'], exclude_patterns
  end

  def test_glob_includes_dotfiles
    # Test that glob method includes dotfiles due to FNM_DOTMATCH flag
    results = Rake::LiberalFileList.glob('.*')

    # Should include hidden files but exclude '.' and '..'
    assert_includes results, '.hidden_file'
    assert_includes results, '.dotfile.rb'
    assert_includes results, '.hidden_dir'
    # Note: '.' but not '..' will be included by glob but excluded by the FileList logic
    assert_includes results, '.'
    refute_includes results, '..'
  end

  def test_glob_with_wildcard_pattern
    results = Rake::LiberalFileList.glob('*')

    # Should include both regular and hidden files/directories
    assert_includes results, 'regular_file.txt'
    assert_includes results, 'another_file.rb'
    assert_includes results, '.hidden_file'
    assert_includes results, '.dotfile.rb'
    assert_includes results, 'subdir'
    assert_includes results, '.hidden_dir'
  end

  def test_glob_with_specific_extension
    results = Rake::LiberalFileList.glob('*.rb')

    # Should include both regular and hidden .rb files
    assert_includes results, 'another_file.rb'
    assert_includes results, '.dotfile.rb'
    refute_includes results, 'regular_file.txt'
  end

  def test_liberal_file_list_vs_regular_file_list
    # Compare LiberalFileList with regular FileList
    liberal_list = Rake::LiberalFileList.new('*')
    regular_list = Rake::FileList.new('*')

    # LiberalFileList should include more files (including dotfiles)
    # but exclude '.' and '..'
    liberal_files = liberal_list.to_a
    regular_files = regular_list.to_a

    # LiberalFileList should include dotfiles that regular FileList excludes
    assert_includes liberal_files, '.hidden_file'
    assert_includes liberal_files, '.dotfile.rb'

    # But should still exclude '.' and '..'
    refute_includes liberal_files, '.'
    refute_includes liberal_files, '..'
  end

  def test_inherits_from_file_list
    file_list = Rake::LiberalFileList.new
    assert_kind_of Rake::FileList, file_list
  end

  def test_exclude_method_still_works
    file_list = Rake::LiberalFileList.new('*')
    file_list.exclude('*.txt')

    # Should exclude .txt files but still include dotfiles
    refute_includes file_list.to_a, 'regular_file.txt'
    assert_includes file_list.to_a, '.hidden_file'
    assert_includes file_list.to_a, '.dotfile.rb'
  end

  def test_glob_method_signature
    # Test that the glob method works with just a pattern
    results = Rake::LiberalFileList.glob('*')
    assert_kind_of Array, results

    # Test that it still works with File::FNM_DOTMATCH implicitly added
    results_with_dotfiles = Rake::LiberalFileList.glob('.*')
    assert_includes results_with_dotfiles, '.hidden_file'
  end

  def test_clear_exclude_functionality
    file_list = Rake::LiberalFileList.new

    # Verify that clear_exclude was called during initialization
    # by checking that default ignore patterns are not present
    exclude_patterns = file_list.instance_variable_get(:@exclude_patterns)

    # Should not contain default ignore patterns like CVS, .svn, etc.
    default_patterns = Rake::FileList::DEFAULT_IGNORE_PATTERNS
    default_patterns.each do |pattern|
      refute_includes exclude_patterns, pattern
    end

    # Should only contain '.' and '..'
    assert_equal ['.', '..'], exclude_patterns
  end

  def test_file_list_includes_dotfiles_in_results
    file_list = Rake::LiberalFileList.new('*')
    results = file_list.to_a

    # Should include dotfiles in the final results
    assert_includes results, '.hidden_file'
    assert_includes results, '.dotfile.rb'
    assert_includes results, '.hidden_dir'

    # But should exclude '.' and '..'
    refute_includes results, '.'
    refute_includes results, '..'
  end
end