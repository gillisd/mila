require 'test_helper'

# test matrix
#
# exclude rel | exclude abs | exclude rel glob (1 level) | exclude rel glob (>1 level) | exclude abs glob (1 level) | exclude abs glob (>1 level)
# exclude; resolve; include | exclude; include; | include; resolve; exclude; | include; exclude;
# pathname | string
# outside env.workdir | inside env.workdir # use chdir env.workdir { <run> }
module Rake
  class FileListTest < Minitest::Test
    include FileUtils
    attr_accessor :env
    FileList = ::Rake::FileList

    def setup
      self.env = Support::Rake::Env.new
      env.mkdir_p 'src'
      env.mkdir_p 'dest'
      env.start
      @current_dir = Dir.pwd
      # chdir env.workdir
    end

    def teardown
      env.stop
      # chdir @current_dir
    end

    # assertions
   def assert_path_exists(path, msg = nil)
      absolute = expand_path path
      super(absolute, msg)
    end

    def assert_list_contains(list, object)
      object = Pathname.new object
      resolved_list = list.resolve.to_a
      contains = resolved_list.include? object.to_s
      message ||= "Expected FileList to contain [#{object}] but did not.\n\n#{print_contents(object)}\n\n#{print_file_list(list)}"
      assert contains, message
    end

    def refute_list_contains(list, object)
      object = Pathname.new object
      resolved_list = list.resolve.to_a
      contains = resolved_list.include? object.to_s
      message ||= "Expected FileList to not contain [#{object}] but did.\n\n#{print_contents(object)}\n\n#{print_file_list(list)}"
      refute contains, message
    end

    # helpers
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
      message = "[DEBUG] Actual contents of [#{object_dir_relative}]:\n#{string}"
    end

    def print_file_list(file_list)
      file_list.resolve
      if (contents = file_list.to_a) && contents.empty?
        "[DEBUG] FileList <empty>"
      else
        string = contents.join("\n")
        "[DEBUG] FileList contents: :\n#{string}"
      end
    end

    # tests

    def test_against_relative_glob
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'
      list = FileList['src/**/*.txt']

      assert_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_string_before
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList.new
      list.exclude 'src/foo.txt'
      list.include 'src/foo.txt'

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_pathname_before
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList.new
      list.exclude Pathname('src/foo.txt')
      list.include 'src/foo.txt'

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_string_before_resolve
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList.new
      list.exclude 'src/foo.txt'
      list.resolve
      list.include 'src/foo.txt'

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_pathname_before_resolve
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList.new
      list.exclude Pathname('src/foo.txt')
      list.resolve
      list.include 'src/foo.txt'

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_string_after
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList['src/foo.txt']
      list.exclude 'src/foo.txt'

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_pathname_after
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList['src/foo.txt']
      list.exclude Pathname('src/foo.txt')

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_absolute_string
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList['src/foo.txt']
      list.exclude expand_path('src/foo.txt').to_s

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_absolute_pathname
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList['src/foo.txt']
      list.exclude expand_path('src/foo.txt')

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_string_after_resolve
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList['src/foo.txt']
      list.resolve
      list.exclude 'src/foo.txt'

      refute_list_contains list, 'src/foo.txt'
    end

    def test_exclude_relative_pathname_after_resolve
      env.touch_file 'src/foo.txt', 'foo'
      assert_path_exists 'src'
      assert_path_exists 'src/foo.txt'

      list = FileList['src/foo.txt']
      list.resolve
      list.exclude Pathname('src/foo.txt')

      refute_list_contains list, 'src/foo.txt'
    end
  end
end