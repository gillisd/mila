require 'tmpdir'

module Support
  module AppleArchive

    module Helpers
      module_function

      def with_apple_archive(path, &block)
        enum = each_archive_file path
        caller = block.binding.receiver

        # extract the assert method from inside the test
        assert_method = caller.method(:assert).to_proc

        # and inject it in here
        asserter = Asserter.new(enum, assert_method: assert_method)

        # and now caller can use this method as so:
        #
        # with_apple_archive path do
        #    assert_archive_contains 'src/file1.txt'
        #    assert_archive_contains 'src/file2.rb'
        # end
        asserter.instance_eval(&block)
      end

      module_function

      def each_archive_file(path, &block)
        return enum_for :each_archive_file, path unless block_given?
        path = Pathname.new(path)
        Dir.mktmpdir do |dir|
          dirpath = Pathname.new(dir).expand_path

          command = ['aa', 'extract'].tap do |c|
            c << '-v' # verbose
            c << '-d' # dirname
            c << dirpath.to_path
            c << '-i'
            c << path.expand_path.to_path # input file
          end

          system(*command)

          dirpath
            .find
            .select(&:file?)
            .map { |child| child.relative_path_from dirpath }
            .map(&:to_path)
            .each { |child| block.call child }
        end
      end
    end

    class Asserter
      include Helpers

      def initialize(archive_enum, assert_method:)
        @assert_method = assert_method
        @archive_enum = archive_enum
      end

      def assert_archive_contains(path)
        @assert_method.call @archive_enum.include?(path)
      end
    end
  end
end