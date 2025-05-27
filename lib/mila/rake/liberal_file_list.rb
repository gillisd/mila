module Mila
  module Rake
    class LiberalFileList < ::Rake::FileList
      def initialize(...)
        super

        clear_exclude
        exclude '.', '..'
      end

      def self.glob(pattern, *args)
        super(pattern, File::FNM_DOTMATCH, *args)
      end
    end
  end
end