module Mila
  module Rake
    class SafeFileList < ::Rake::FileList
      def resolve_add(fn)
        fn = expand_path(fn)
        super(fn)
      end

      private

      def expand_path(object)
        workdir = Pathname.pwd
        object_pathname = Pathname.new(object)
        if object_pathname.relative?
          workdir.join(object_pathname).expand_path
        else
          object_pathname.expand_path
        end
      end
    end
  end
end