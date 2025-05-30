require 'forwardable'
require 'stringio'
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
      include FileUtils
      include ::Rake::PrivateReader
      include ::Rake::DSL
      include Mila::Lockable
      extend Forwardable

      attr_accessor :destination_dir, :root_dir, :concurrent, :prefer_hard_links, :description, :force_hard_links
      attr_reader :include_dotfiles

      private_reader :__sources

      def_delegator :__sources, :include, :exclude

      lock_writers :include, :description, :destination_dir, :root_dir, :prefer_hard_links, :concurrent, :include_dotfiles, :force_hard_links, :before_copy, on: :lock_writers!

      def initialize(name)
        @fileutils_output = $stderr
        @prefer_hard_links = true
        @force_hard_links = false
        @include_dotfiles = false
        @concurrent = true
        @name = name
        @root_dir = Pathname.new(__dir__)
        @includes = []
        @before_copy_hooks = []
        @excludes = []
        yield self

        [:root_dir, :destination_dir].each do |req|
          raise ArgumentError, "Required argument #{req} was not present" if public_send(req).nil?
        end

        lock_writers!
        compile_source_list
        define!
      end

      def compile_source_list
        @__sources ||= new_file_list
        # resolve_excludes
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

      def before_copy(&block)
        @before_copy_hooks << block if block_given?
      end

      def exclude(*args, &block)
        @excludes << [args, block].flatten
      end

      private

      def new_file_list
        default_prock = lambda { |list|
          list.exclude '**/.DS_Store'
        }

        if include_dotfiles
          LiberalFileList.new.tap(&default_prock)
        else
          ::Rake::FileList.new.tap do |list|
            list.clear_exclude
            default_prock.call(list)
          end
        end
      end

      def resolve_includes
        resolve_excludes
        resolve_file_list(@includes, verb: :include, file_list: __sources)
      end

      def resolve_excludes
        compacted = @excludes.flatten.compact
        procs = compacted.select { Proc === _1 }
        rest = compacted - procs
        resolve_file_list(rest, verb: :exclude, file_list: __sources)
        procs.each { |proc| __sources.exclude(&proc) }
        __sources
      end

      def resolve_file_list(list, verb:, file_list:)
        chdir @root_dir, verbose: false do
          list.flatten.each do |pattern|
            pathname = Pathname.new(pattern)
            is_glob = pattern.to_s.include?('*')
            root_dir_pathname = Pathname.new(@root_dir).expand_path
            case [pathname.exist?, pathname.directory?, pathname.relative?, is_glob]
            in true, true, true, false # a relative directory
              absolute_pathname = root_dir_pathname.join(pathname)
              file_list.send verb, absolute_pathname.join('**/*').to_s
            in true, true, false, false # an absolute directory
              file_list.send verb, pathname.join('**/*').to_s
            in _, _, _, true # a glob pattern
              nearest_dir_without_glob = pathname
                                           .ascend
                                           .find {
                                             |path| path.directory? && path.exist?
                                           }

              absolute_glob = nil
              if nearest_dir_without_glob.nil?
                nearest_dir_without_glob = root_dir_pathname
                absolute_glob = nearest_dir_without_glob.join(pathname)
              end

              if nearest_dir_without_glob.relative?
                absolute_glob = root_dir_pathname.join(pathname)
                file_list.send verb, absolute_glob.to_s
              else
                file_list.send verb, absolute_glob.to_s
              end
            in _, _, true, false # a file or a relative file
              absolute_pathname = root_dir_pathname.join(pathname)
              file_list.send verb, absolute_pathname.to_s
            in _, _, false, false # an absolute file
              file_list.send verb, pathname.to_s
            else
              raise ArgumentError, "Invalid pattern: #{pattern.inspect}"
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
        file(...)
        # file_task_klass.define_task(...)
      end

      def safe_hard_link(source, target)
        case [prefer_hard_links, force_hard_links]
        in true, true
          # warn 'Using hard links'
          begin
            ln source, target, force: true
          rescue => e
            warn 'Failed to create hard link, falling back to regular copy'
          end
        in true, false
          warn 'Using hard links, but will fall back to regular copy if hard link fails'

          begin
            safe_ln source, target
          rescue ArgumentError => e
            if e.message =~ /same file/
              warn 'File already exists'
              return
            end

            raise e
          end
        in false, _
          warn 'Using regular copy'
          return cp source, target
        else
          raise 'Invalid combination of prefer_hard_links and force_hard_links'
        end
      end

      def define!
        directory destination_dir

        absolute_sources = source_files
                             .map { |source| Pathname.new(source) }
                             .map { |source| root_dir_path.join(source) }
                             .reject(&:directory?) # must be here to reject as we now have absolute paths

        finalized_targets = LiberalFileList.new.tap do |finalized_targets|
          absolute_sources.zip(target_files).each do |source, target|
            editable_target = EditableFile.new(target, content_path: source)
            @before_copy_hooks.each { |hook| hook.call editable_target }

            target_pathname = editable_target
            directory target_pathname.parent

            CLEAN.include target_pathname

            file_task target_pathname => [source, destination_dir, target_pathname.parent] do
              if editable_target.dirty?
                editable_target.save
              else
                safe_hard_link source, target_pathname
              end
            end

            finalized_targets.include target_pathname
          end
        end

        finalized_targets.resolve

        desc description if description
        send(task_method, @name.to_sym => finalized_targets)
      end
    end
  end
end
