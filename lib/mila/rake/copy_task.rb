require 'forwardable'
require 'rake/clean'
# require_relative '../concerns/lockable'
# require_relative '../multi_file_task'

class File
  def self.sparse?(file_path)
    stat = File.stat(file_path)

    # Calculate expected blocks for a non-sparse file
    # Block size is typically 512 bytes on most systems
    block_size = 512
    expected_blocks = (stat.size + block_size - 1) / block_size

    # If actual blocks < expected blocks, it's sparse
    stat.blocks < expected_blocks
  end
end

class Pathname
  def sparse?
    File.sparse? expand_path.to_s
  end
end

module Mila
  module Rake
    class CopyTask < ::Rake::TaskLib
      include ::Rake::PrivateReader
      include ::Rake::DSL
      include Mila::Lockable
      extend Forwardable

      attr_accessor :destination_dir, :root_dir, :concurrent, :prefer_hard_links, :description
      attr_reader :include_dotfiles

      private_reader :__sources

      def_delegator :__sources, :include, :exclude

      lock_writers :include, :description, :destination_dir, :root_dir, :prefer_hard_links, :concurrent, :include_dotfiles, on: :lock_writers!

      def initialize(name)
        @prefer_hard_links = true
        @include_dotfiles = false
        @concurrent = true
        @name = name
        @root_dir = Pathname.new(__dir__)
        @includes = []
        @excludes = []
        yield self

        [:root_dir, :destination_dir].each do |req|
          raise ArgumentError, "Required argument #{req} was not present" if public_send(req).nil?
        end

        compile_source_list
        define!
        lock_writers!
      end

      def compile_source_list
        @__sources = new_file_list
        resolve_excludes
        resolve_includes
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
          source_files
            .map { |source| destination_dir_path.join(source) }
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
          compile_source_list
        else
          # pass
        end
      end

      def include(*args)
        @includes << args
      end

      def exclude(*args, &block)
        @excludes << [args, block].flatten
      end

      private

      def new_file_list
        default_prock = lambda { |list|
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
        resolved = resolve_file_list(@includes)
        __sources.include resolved
      end

      def resolve_excludes
        compacted = @excludes.flatten.compact
        procs = compacted.select { _1 in Proc }
        rest = compacted - procs
        resolved = resolve_file_list(rest)
        __sources.exclude resolved
        procs.each { |proc| __sources.exclude(&proc) }
        __sources
      end

      def resolve_file_list(list)
        new_file_list.tap do |__sources|
          chdir @root_dir, verbose: false do
            list.flatten.each do |pattern|
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
          end
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

      def file_task(...)
        file_task_klass.define_task(...)
      end

      def safe_hard_link(source, target)
        unless @prefer_hard_links
          warn 'Using regular copy'
          return cp source, target
        end

        begin
          safe_ln source, target
        rescue ArgumentError => e
          if e.message =~ /same file/
            warn 'File already exists'
            return
          end

          raise e
        end
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

          CLEAN.include target_pathname

          file_task target_pathname => [source, destination_dir, target_pathname.parent] do
            safe_hard_link source, target_pathname
          end
        end

        desc description if description
        send(task_method, @name.to_sym => new_file_list.include(target_files))
      end
    end
  end
end

