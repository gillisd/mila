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

    def load_fixture(name)
      with_fixture(name) do |file|
        puts file
        case [file.basename, file.extname]
        in _, /\.gz$/
          Zlib::GzipReader.wrap(file) { |gz| gz.read }
        in _, '.json'
          ::JSON.load(file, symbolize_names: true)
        else
          file.read
        end
      end
    end

    def with_fixture(name)
      DEFAULT_FIXTURE_PATHNAME.join(name).open do |file|
        yield FileProxy.new(file)
      end
    end
  end
end