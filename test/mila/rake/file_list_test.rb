require 'test_helper'
class FileListExcludeTest < Minitest::Test
  include FileUtils
  attr_accessor :env
  FileList = ::Mila::Rake::SafeFileList

  def setup
    self.env = Support::Rake::Env.new
    env.mkdir_p 'src'
    env.mkdir_p 'dest'
    env.start
    @current_dir = Dir.pwd
  end

  def teardown
    env.stop
  end

  # Shared helper methods
  def assert_path_exists(path, msg = nil)
    absolute = expand_path path
    super(absolute, msg)
  end

  def assert_list_contains(list, object)
    object = Pathname.new object
    resolved_list = list.resolve.to_a
    contains = resolved_list.include? object.to_s
    message = "Expected FileList to contain [#{object}] but did not.\n\n#{print_contents(object)}\n\n#{print_file_list(list)}"
    assert contains, message
  end

  def refute_list_contains(list, object)
    object = Pathname.new object
    resolved_list = list.resolve.to_a
    contains = resolved_list.include? object.to_s
    message = "Expected FileList to not contain [#{object}] but did.\n\n#{print_contents(object)}\n\n#{print_file_list(list)}"
    refute contains, message
  end

  def expand_path(object)
    workdir = env.workdir
    object_pathname = Pathname.new(object)
    if object_pathname.relative?
      workdir.join(object_pathname).expand_path
    else
      object_pathname.expand_path
    end
  end

  def print_contents(object)
    object_dir = expand_path(object).parent
    absolute_contents = object_dir.find.to_a - [object_dir]
    object_dir_relative = object_dir.relative_path_from env.workdir
    relative_contents = absolute_contents.map { _1.relative_path_from env.workdir }
    string = relative_contents.join("\n")
    "[DEBUG] Actual contents of [#{object_dir_relative}]:\n#{string}"
  end

  def print_file_list(file_list)
    file_list.resolve
    if (contents = file_list.to_a) && contents.empty?
      "[DEBUG] FileList <empty>"
    else
      string = contents.join("\n")
      "[DEBUG] FileList contents:\n#{string}"
    end
  end
end

class FileListExcludeOutsideWorkdirTest < FileListExcludeTest
  def setup
    @current_dir = __dir__
    super
    refute_equal Dir.home, Dir.pwd
    chdir Dir.home
    # stay outside env.workdir
  end

  def teardown
    assert_equal Dir.home, Dir.pwd
    chdir @current_dir
  end

  # Relative paths - String
  def test_exclude_relative_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude 'src/foo.txt'
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude 'src/foo.txt'
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.exclude 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative paths - Pathname
  def test_exclude_relative_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude Pathname('src/foo.txt')
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude Pathname('src/foo.txt')
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.exclude Pathname('src/foo.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude Pathname('src/foo.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute paths - String
  def test_exclude_absolute_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList.new
    list.exclude absolute_path
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList.new
    list.exclude absolute_path
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList['src/foo.txt']
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute paths - Pathname
  def test_exclude_absolute_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList.new
    list.exclude absolute_path
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList.new
    list.exclude absolute_path
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList['src/foo.txt']
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (1 level) - String
  def test_exclude_relative_glob_1level_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude 'src/*.txt'
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude 'src/*.txt'
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.exclude 'src/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude 'src/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (1 level) - Pathname
  def test_exclude_relative_glob_1level_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude Pathname('src/*.txt')
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude Pathname('src/*.txt')
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.exclude Pathname('src/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude Pathname('src/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (>1 level) - String
  def test_exclude_relative_glob_multilevel_string_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude 'src/**/*.txt'
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_string_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude 'src/**/*.txt'
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_string_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.exclude 'src/**/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_string_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude 'src/**/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (>1 level) - Pathname
  def test_exclude_relative_glob_multilevel_pathname_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude Pathname('src/**/*.txt')
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_pathname_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude Pathname('src/**/*.txt')
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_pathname_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.exclude Pathname('src/**/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_pathname_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude Pathname('src/**/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (1 level) - String
  def test_exclude_absolute_glob_1level_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (1 level) - Pathname
  def test_exclude_absolute_glob_1level_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (>1 level) - String
  def test_exclude_absolute_glob_multilevel_string_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_string_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_string_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_string_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (>1 level) - Pathname
  def test_exclude_absolute_glob_multilevel_pathname_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_pathname_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_pathname_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_pathname_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end
end

class FileListExcludeInsideWorkdirTest < FileListExcludeTest
  def setup
    super
    chdir env.workdir # Work inside env.workdir
  end

  def teardown
    chdir @current_dir
    super
  end

  # Relative paths - String
  def test_exclude_relative_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude 'src/foo.txt'
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude 'src/foo.txt'
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.exclude 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative paths - Pathname
  def test_exclude_relative_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude Pathname('src/foo.txt')
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList.new
    list.exclude Pathname('src/foo.txt')
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.exclude Pathname('src/foo.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude Pathname('src/foo.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute paths - String
  def test_exclude_absolute_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList.new
    list.exclude absolute_path
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList.new
    list.exclude absolute_path
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList['src/foo.txt']
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt').to_s

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute paths - Pathname
  def test_exclude_absolute_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList.new
    list.exclude absolute_path
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList.new
    list.exclude absolute_path
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList['src/foo.txt']
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'

    absolute_path = expand_path('src/foo.txt')

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_path

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (1 level) - String
  def test_exclude_relative_glob_1level_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude 'src/*.txt'
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude 'src/*.txt'
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.exclude 'src/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude 'src/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (1 level) - Pathname
  def test_exclude_relative_glob_1level_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude Pathname('src/*.txt')
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList.new
    list.exclude Pathname('src/*.txt')
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.exclude Pathname('src/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_1level_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude Pathname('src/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (>1 level) - String
  def test_exclude_relative_glob_multilevel_string_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude 'src/**/*.txt'
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_string_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude 'src/**/*.txt'
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_string_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.exclude 'src/**/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_string_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude 'src/**/*.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  # Relative globs (>1 level) - Pathname
  def test_exclude_relative_glob_multilevel_pathname_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude Pathname('src/**/*.txt')
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_pathname_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList.new
    list.exclude Pathname('src/**/*.txt')
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_pathname_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.exclude Pathname('src/**/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_relative_glob_multilevel_pathname_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude Pathname('src/**/*.txt')

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (1 level) - String
  def test_exclude_absolute_glob_1level_string_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_string_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_string_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_string_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt').to_s

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (1 level) - Pathname
  def test_exclude_absolute_glob_1level_pathname_exclude_then_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_pathname_exclude_resolve_include
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_pathname_include_then_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_1level_pathname_include_resolve_exclude
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/bar.txt', 'bar'
    assert_path_exists 'src'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/bar.txt'

    absolute_glob = expand_path('src').join('*.txt')

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (>1 level) - String
  def test_exclude_absolute_glob_multilevel_string_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_string_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_string_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_string_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt').to_s

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  # Absolute globs (>1 level) - Pathname
  def test_exclude_absolute_glob_multilevel_pathname_exclude_then_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_pathname_exclude_resolve_include
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList.new
    list.exclude absolute_glob
    list.resolve
    list.include 'src/foo.txt'

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_pathname_include_then_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList['src/foo.txt']
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end

  def test_exclude_absolute_glob_multilevel_pathname_include_resolve_exclude
    env.mkdir_p 'src/deep/nested'
    env.touch_file 'src/foo.txt', 'foo'
    env.touch_file 'src/deep/bar.txt', 'bar'
    env.touch_file 'src/deep/nested/baz.txt', 'baz'
    assert_path_exists 'src/deep/nested'
    assert_path_exists 'src/foo.txt'
    assert_path_exists 'src/deep/bar.txt'
    assert_path_exists 'src/deep/nested/baz.txt'

    absolute_glob = expand_path('src').join('**/*.txt')

    list = FileList['src/foo.txt']
    list.resolve
    list.exclude absolute_glob

    refute_list_contains list, 'src/foo.txt'
  end
end