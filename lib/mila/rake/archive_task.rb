require 'rake/tasklib'
require 'delegate'
require 'shellwords'
require 'tmpdir'
require_relative 'copy_task'

module Mila
  module Rake
    class ArchiveTask < ::Rake::TaskLib
      attr_accessor :name, :destination_path, :root_dir, :concurrent, :include

      class AppleArchiveCommand
        def initialize(destination: Dir.pwd)
          @destination = Pathname.new(destination)
        end

        def command_arr
          ["aa", "archive"].tap do |c|
            c << '-v' # verbose
            c << '-d' # directory
            c << '.' # current location
            c << '-o' # output file
            c << @destination
          end
        end

        def to_s
          Shellwords.join(command_arr)
        end
      end

      class TarCommand
        def initialize(compress: true, destination: Dir.pwd)
          @compress = compress
          @destination = Pathname.new(destination)
        end

        def find_command_arr
          # ['find', '.', '-type', 'f']
        end

        def tar_command_arr
          ['tar'].tap do |arr|
            arr << '-cvf'
            arr << @destination.to_path
            if @compress
              arr << '-z'
            end
            arr << '.'
            # arr << '-T'
            # arr << '-'
          end
        end

        def to_s
          # Shellwords.join(find_command_arr) + ' | ' + Shellwords.join(tar_command_arr)
          Shellwords.join(tar_command_arr)
        end
      end

      class ZipCommand
        def initialize(destination: Dir.pwd)
          @destination = Pathname.new(destination)
        end

        def command_arr
          ['zip', '-r', @destination.to_path, '.']
        end

        def to_s
          Shellwords.join(command_arr)
        end
      end

      class Proxy < SimpleDelegator
        def initialize(archive_task:, copy_task:)
          super(archive_task)
          @archive_task = archive_task
          @copy_task = copy_task
        end

        def include_dotfiles=(value)
          @copy_task.include_dotfiles = value
        end

        def include(*args)
          @copy_task.include(*args)
        end
      end

      def initialize(name = :archive, root_dir: Dir.pwd, destination_path: Dir.pwd, concurrent: true, &block)
        @name = name
        @root_dir = Pathname.new root_dir
        @destination_path = Pathname.new destination_path
        @concurrent = concurrent
        @staging_dir_pathname = Pathname.new(Dir.mktmpdir)

        define_copy_task do |copy_task|
          block.call Proxy.new(archive_task: self, copy_task: copy_task)
          validate_attributes!
        end

        ensure_directories_created!

        define
      end

      private

      def ensure_directories_created!
        parent = Pathname.new(@destination_path).parent
        mkdir_p parent
      end

      def define_copy_task(&block)
        namespace :archive do
          CopyTask.new :copy_files do |copy_task|
            block.call copy_task
            copy_task.root_dir = root_dir
            copy_task.concurrent = concurrent
            copy_task.destination_dir = @staging_dir_pathname
          end
        end
      end

      def validate_attributes!
        [:root_dir, :destination_path, :name, :concurrent].each do |attribute|
          if public_send(attribute).nil?
            raise ArgumentError, "Attribute \"#{attribute}\" was nil"
          end
        end
      end

      def archive_extension
        @destination_path.extname
      end

      def command
        extension = absolute_target_archive_path
                      .to_s
                      .split('/')
                      .last
                      .split('.')
                      .then { |it| it[1..] }
                      .compact
                      .reject(&:empty?)
        case extension
        in 'tar', 'gz' then TarCommand.new(compress: true, destination: absolute_target_archive_path.to_path)
        in ['tar'] then TarCommand.new(compress: false, destination: absolute_target_archive_path.to_path)
        in ['zip'] then ZipCommand.new(destination: absolute_target_archive_path.to_path)
        in ['aar' | 'aarchive'] then AppleArchiveCommand.new(destination: absolute_target_archive_path.to_path)
        else raise ArgumentError, "Unsupported archive extension: #{archive_extension}"
        end
      end

      def define
        namespace :archive do
          file absolute_target_archive_path => ['archive:copy_files'] do
            chdir @staging_dir_pathname do
              sh command.to_s
            end
          end
        end

        desc 'archive task'
        task @name => absolute_target_archive_path
      end

      def workdir_pathname
        Pathname.new(Dir.pwd)
      end

      def absolute_target_archive_path
        target_archive = Pathname.new destination_path
        case target_archive.relative?
        in true then workdir_pathname.join(target_archive).expand_path
        else target_archive.expand_path
        end
      end
    end
  end
end