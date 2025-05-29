require 'rake/tasklib'
require 'delegate'
require 'shellwords'
require 'tmpdir'
require 'rake/clean'
require_relative 'copy_task'

module Mila
  module Rake
    class ArchiveTask < ::Rake::TaskLib
      attr_accessor :name, :destination_path, :root_dir, :concurrent, :include, :description

      class AppleArchiveCommand
        def initialize(destination: Dir.pwd)
          @destination = Pathname.new(destination)
        end

        def command_arr
          %w[aa archive].tap do |c|
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

        def tar_command_arr
          ['tar'].tap do |arr|
            arr << '-cvf'
            arr << @destination.to_path
            if @compress
              arr << '-z'
            end
            arr << '.'
          end
        end

        def to_s
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
        extend Forwardable

        def_delegators :@copy_task, :include, :exclude, :include_dotfiles=

        def initialize(archive_task:, copy_task:)
          super(archive_task)
          @archive_task = archive_task
          @copy_task = copy_task
        end
      end

      def initialize(name, root_dir: Dir.pwd, destination_path: Dir.pwd, concurrent: true, include_dotfiles: true, &block)
        @name = name
        @root_dir = Pathname.new root_dir
        @destination_path = Pathname.new destination_path
        @include_dotfiles = include_dotfiles
        @concurrent = concurrent
        @copy_task = nil

        define_copy_task do |copy_task|
          proxy = Proxy.new(archive_task: self, copy_task: copy_task)
          block.call proxy
          validate_attributes!
        end
        directory Pathname.new(@destination_path).parent
        define
      end

      private

      def tmp_dir
        return @tmp_dir if @tmp_dir&.present?
        raise ArgumentError, 'Archive name is not set' if @name.nil? || @name.empty?
        @tmp_dir ||= Pathname.new('/tmp').join("rake/archive_task/#{@name}")
        directory @tmp_dir
       # CLEAN.add @tmp_dir
        @tmp_dir
      end

      def define_copy_task(&block)
        namespace :archive do
          namespace @name do
            @copy_task = CopyTask.new :copy_files do |copy_task|
              block.call copy_task
              copy_task.exclude absolute_target_archive_path
              copy_task.exclude @destination_path
              copy_task.include_dotfiles = true
              copy_task.root_dir = root_dir
              copy_task.concurrent = concurrent
              copy_task.destination_dir = tmp_dir
            end
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

      def file_task(*args, &block)
        file_task_klass.define_task(*args, &block)
      end

      def define
        directory absolute_target_archive_path.dirname

        copy_targets = FileList.new do |l|
          l.include @copy_task&.target_files
          l.include absolute_target_archive_path.dirname
        end

        file_task absolute_target_archive_path => copy_targets do
          chdir tmp_dir do
            sh command.to_s
          end
        end

        desc description
        task @name => absolute_target_archive_path
      end

      def workdir_pathname
        Pathname.new(Dir.pwd)
      end

      def file_task_klass
        case concurrent
        in true then MultiFileTask
        in false then ::Rake::FileTask
        else raise 'Invalid concurrent flag'
        end
      end

      def absolute_target_archive_path
        @absolute_target_archive_path ||= (
          target_archive = Pathname.new destination_path
          case target_archive.relative?
          in true then workdir_pathname.join(target_archive).expand_path
          else target_archive.expand_path
          end
        )
      end
    end
  end
end
