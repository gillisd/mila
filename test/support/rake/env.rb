# require 'rake'
require 'rake'
require 'rake/application'
# require 'pathname'
# require 'forwardable'
# require 'rake/application'
# require 'securerandom'
module Support
  module Rake
    class Env
      include FileUtils
      extend Forwardable

      include ::Rake

      attr_reader :app, :workdir

      @mutex = Mutex.new

      def self.acquire
        @mutex.lock
      end

      def self.release
        @mutex.unlock
      end

      def initialize(caller_binding, workdir: Dir.mktmpdir(SecureRandom.alphanumeric(10)))
        @caller_binding = caller_binding
        @workdir = Pathname.new(workdir)
        @app = Application.new
        @files = FileList.new
        @directories = FileList[@workdir]
        @current_dir = __dir__
      end

      def start
        self.class.acquire
        ::Rake.application = app

        # chdir workdir
        save_rakefile
        chdir @workdir do
          app.load_rakefile
        end
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
        Task.define_task(name, &block)
      end

      def invoke_task(name)
        Task[name].invoke
      end

      def task_exists?(name)
        Task.task_defined?(name)
      end

      def stop
        return unless app
        ::Rake.application = nil
        @app = nil
        @files.each { |file| safe_unlink file }
        @directories.each { |dir| rm_rf dir }
        # chdir @current_dir
        self.class.release
      end

      private

      def save_rakefile
        touch_file 'Rakefile'
        @files.add 'Rakefile'
      end
    end
  end
end