# require 'rake'

module ::Rake
  def application
    Thread.current[:__rake_app] ||= Rake::Application.new
  end
end

require 'rake'
require 'rake/application'
require 'securerandom'
require 'pathname'
require 'forwardable'

module Support
  module Rake
    class Env
      include FileUtils
      extend Forwardable

      attr_reader :app, :workdir

      def initialize(workdir: Dir.mktmpdir(SecureRandom.alphanumeric(10)))
        @workdir = Pathname.new(workdir)
        @files = FileList.new
        @directories = FileList[@workdir]
        @current_dir = __dir__
      end

      def app
        ::Rake.application
      end

      def start
        chdir workdir
        save_rakefile
        app.load_rakefile
      end

      def touch_file(filename, content = "# Created by Support::Env at #{Time.now}\n")
        path = path_for filename
        mkdir_p path.parent
        open_file(filename, 'w') do |file|
          file.write content
        end
      rescue Errno::ENOENT
        raise "File not found: #{pathname}"
      end

      def mkdir_p(dirname)
        pathname = path_for(dirname)

        super(pathname.expand_path)
      rescue Errno::EEXIST
        # Directory already exists, do nothing
      ensure
        @directories.add pathname
      end

      def path_for(filename)
        input_path = Pathname.new filename
        resolved = (
          if input_path.relative?
            workdir.join(input_path)
          else
            input_path
          end
        )
        resolved.expand_path
      end

      def open_file(filename, mode = 'r')
        pathname = path_for filename
        pathname.open(mode) do |file|
          yield file
        end
      rescue Errno::ENOENT
        raise "File not found: #{pathname.to_path}"
      ensure
        @files.add pathname
      end

      def define_task(name, &block)
        ::Rake::Task.define_task(name, &block)
      end

      def invoke_task(name)
        ::Rake::Task[name].invoke
      end

      def task_exists?(name)
        ::Rake::Task.task_defined?(name)
      end

      def stop
        # return unless app
        ::Rake.application = nil
        # @app = nil
        @files.each { |file| safe_unlink file }
        @directories.each { |dir| rm_rf dir }
        # self.class.release
      end

      private

      def save_rakefile
        touch_file 'Rakefile', 'require "pathname"'
        @files.add path_for('Rakefile')
      end
    end
  end
end
