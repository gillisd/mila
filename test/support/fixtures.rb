module Support
  module Fixtures
    using Mila::Refinements::String

    DEFAULT_FIXTURE_PATHNAME = __dir__.to_pathname.join('fixtures').expand_path

    class FileProxy < SimpleDelegator
      using Mila::Refinements::String

      def pathname
        __getobj__.path.to_pathname
      end

      (Pathname.public_instance_methods - Object.methods).each do |m|
        next if m.to_s.start_with?('_')
        define_method(m) do |*args, &block|
          pathname.send(m, *args, &block)
        end
      end
    end

    def load_fixture(name, format: :auto)
      with_fixture(name) do |file|
        output_format = format == :auto ? file.extname : format

        case [file.basename, output_format]
        in _, :string
          file.read
        in _, /\.gz$/
          handle_gzip(file)
        in _, '.json'
          handle_json(file)
        in _, :auto
          file.read
        else
          raise ArgumentError, "Unsupported output format: #{output_format}"
        end
      end
    end

    def with_fixture(name)
      DEFAULT_FIXTURE_PATHNAME.join(name).open do |file|
        yield FileProxy.new(file)
      end
    end

    private

    def handle_json(file)
      ::JSON.load(file, symbolize_names: true)
    end

    def handle_gzip(file)
      Zlib::GzipReader.wrap(file) { |gz| gz.read }
    end
  end
end