require 'tmpdir'
require 'pathname'

module Support
  module AppleArchive
    module_function

    def extract_files(path)
      path = Pathname.new(path)

      Dir.mktmpdir do |dir|
        dirpath = Pathname.new(dir).expand_path

        command = [
          'aa', 'extract',
          '-v', # verbose
          '-d', dirpath.to_s, # destination directory
          '-i', path.expand_path.to_s # input file
        ]

        success = system(*command)
        raise "Failed to extract archive: #{path}" unless success

        dirpath
          .find
          .select(&:file?)
          .map { |child| child.relative_path_from(dirpath).to_s }
      end
    end

    def assert_archive_contains(path, file_path)
      assert archive_contains?(path, file_path), "Expected archive #{path} to contain #{file_path}, but contained:\n#{extract_files(path).join("\n")}"
    end

    def archive_contains?(path, file_path)
      extract_files(path).include?(file_path)
    end
  end
end