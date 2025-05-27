# require 'rake'
# require 'rake/tasklib'
# require_relative 'rake/liberal_file_list'
# require 'forwardable'
# require_relative 'rake/multi_file_task'
# require_relative 'lockable'

require 'forwardable'
module Mila
  module Rake
    class CopyTask < ::Rake::TaskLib
      include ::Rake::PrivateReader
      include ::Rake::DSL
      include Mila::Lockable
      extend Forwardable

      attr_accessor :destination_dir, :root_dir, :concurrent, :prefer_hard_links
      attr_reader :include_dotfiles

      private_reader :__sources

      def_delegator :__sources, :include, :exclude

      lock_writers :include, :destination_dir, :root_dir, :prefer_hard_links, :concurrent, :include_dotfiles, on: :lock_writers!

      def initialize(name)
        @prefer_hard_links = true
        @include_dotfiles = false
        @concurrent = true
        @name = name
        @__sources = new_file_list
        @root_dir = Pathname.new(__dir__)
        @includes = []
        yield self

        [:root_dir, :destination_dir].each do |req|
          raise ArgumentError, "Required argument #{req} was not present" if public_send(req).nil?
        end

        resolve_includes
        define!
        lock_writers!
      end

      def source_files
        @source_files ||= __sources
                            .resolve
                            .map { |source| Pathname.new(source) }
                            .map { |source| source.relative? ? root_dir_path.join(source) : source }
                            .reject(&:directory?) # must be here to reject as we now have absolute paths
                            .map { |source| relative_path_from_root source }
                            .then { |it| new_file_list.include(it) }
      end

      def target_files
        @target_files ||= destination_dir
                            .then { |it| Pathname.new it }
                            .then { |destination_dir_path|
                              source_files.map { |source| destination_dir_path.join(source) }
                                          .then { |it| new_file_list.include(it) }
                            }
      end

      def root_dir_path
        Pathname.new(root_dir)
      end

      def include_dotfiles=(value)
        previous_value = @include_dotfiles
        @include_dotfiles = value
        case [@include_dotfiles, previous_value]
        in true, false
          @__sources = LiberalFileList.new.import __sources
        else
          # pass
        end
      end

      def include(*args)
        @includes << args
      end

      private

      def new_file_list
        default_prock = ->(list) {
          list.exclude '**/.DS_Store'
        }

        if @include_dotfiles
          LiberalFileList.new.tap(&default_prock)
        else
          ::Rake::FileList.new.tap do |list|
            list.clear_exclude
            default_prock.call(list)
          end
        end
      end

      def resolve_includes
        chdir @root_dir, verbose: false do
          @includes.flatten.each do |pattern|
            pathname = Pathname.new(pattern)
            case [pathname.exist?, pathname.directory?, pathname.relative?]
            in true, true, true
              absolute_pathname = Pathname.new(@root_dir).join(pathname)
              __sources.include absolute_pathname.join('**/*')
            in true, true, false
              __sources.include pathname.join('**/*')
            else
              __sources.include(pattern)
            end
          end

          __sources.resolve
        end
      end

      def relative_path_from_root(path)
        relative_path_from path, @root_dir
      end

      def relative_path_from(child, parent)
        parent_pathname = Pathname.new(parent)
        child_pathname = Pathname.new(child)
        child_pathname.relative_path_from(parent_pathname)
      end

      def glob_all_files(dir)
        dir_pathname = Pathname.new(dir)
        dir_pathname.glob('**/*', File::FNM_DOTMATCH)
      end

      def file_task_klass
        case concurrent
        in true then MultiFileTask
        in false then ::Rake::FileTask
        else raise 'Invalid concurrent flag'
        end
      end

      def task_method
        case concurrent
        in true then :multitask
        in false then :task
        else raise 'Invalid concurrent flag'
        end
      end

      def file_task(*args, &block)
        file_task_klass.define_task(*args, &block)
      end

      def safe_hard_link(source, target)
        return cp source, target unless @prefer_hard_links

        safe_ln source, target
      end

      def define!
        directory destination_dir

        absolute_sources = source_files
                             .map { |source| Pathname.new(source) }
                             .map { |source| root_dir_path.join(source) }
                             .reject(&:directory?) # must be here to reject as we now have absolute paths

        absolute_sources.zip(target_files).each do |source, target|
          target_pathname = Pathname.new(target)
          directory target_pathname.parent
          file_task target_pathname => [source, destination_dir, target_pathname.parent] do
            safe_hard_link source, target_pathname
          end
        end

        send(task_method, @name.to_sym => new_file_list.include(target_files))
      end
    end
  end
end