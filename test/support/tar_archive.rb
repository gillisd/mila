require 'rubygems/package'
require 'rake/file_list'

module Support
  module TarArchive
    module_function

    def list_files(readable)
      io = (
        case readable
        in Zlib::GzipReader then readable
        in Pathname then readable.open('rb')
        in String then File.open(readable, 'rb')
        in IO then readable
        else raise ArgumentError, "Expected Pathname, String, or IO, got #{readable.class}"
        end
      )
      io.rewind

      tar_files = FileList.new

      begin
        tar = Gem::Package::TarReader.new(io)
        files = tar.to_a.map(&:full_name).reject { |name| name.end_with?('/') }
        tar_files.import files
      rescue Gem::Package::TarInvalidError => e
        warn "Failed to read tar archive: #{e.message}"
      end

      tar_files.reject { File.directory? _1 }
    end

    def extract_files(path)
      # For consistency with AppleArchive pattern, though list_files is usually sufficient
      list_files(path)
    end

    def assert_archive_contains(path, file_path)
      assert archive_contains?(path, file_path), "Expected archive #{path} to contain #{file_path}, but contained:\n#{list_files(path).join("\n")}"
    end

    def assert_compressed_archive_contains(path, file_path)
      assert compressed_archive_contains?(path, file_path), "Expected compressed archive #{path} to contain #{file_path}\n#{list_files(path).join("\n")}"
    end

    def refute_archive_contains(path, file_path)
      refute archive_contains?(path, file_path), "Expected archive #{path} not to contain #{file_path}, but it did."
    end

    def refute_compressed_archive_contains(path, file_path)
      refute compressed_archive_contains?(path, file_path), "Expected compressed archive #{path} not to contain #{file_path}, but it did."
    end

    def compressed_archive_contains?(path, file_path)
      path = Pathname.new(path)
      path.open('rb') do |io|
        reader = Zlib::GzipReader.wrap io
        begin
          list_files(reader).include?(file_path)
        ensure
          reader.close
        end
      end
    end

    def archive_contains?(path, file_path)
      list_files(path).include?(file_path)
    end

    def archive_contains_pattern?(path, pattern)
      files = list_files(path)
      case pattern
      when Regexp
        files.any? { |file| file.match?(pattern) }
      when String
        files.include?(pattern)
      else
        raise ArgumentError, "Pattern must be String or Regexp"
      end
    end
  end
end
