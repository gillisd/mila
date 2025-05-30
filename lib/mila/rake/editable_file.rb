module Mila
  module Rake

    class EditableFile
      include FileUtils
      attr_reader :path, :dirty

      alias dirty? dirty
      alias pathname path

      extend Forwardable

      def_delegators :path, :read, :basename, :parent, :to_s, :to_path, :exist?, :expand_path, :dirname, :join

      def initialize(path, content_path: nil)
        @content_path = content_path
        @dirty = false
        @path = Pathname.new(path).expand_path
        @clean_path = @path.dup
        @transformations = []
        @to_delete = Set.new
      end

      def basename=(new_name)
        current_path = @path
        new_path = current_path
                     .expand_path
                     .dirname
                     .join(new_name)

        if path.exist?
          create_transformation do |f|
            current_path.rename(new_path)
          end
        end
        @path = new_path
      end

      def save
        return unless dirty?
        apply_transformations!
        cleanup
        reset!
        self
      end

      def gsub!(pattern, replacement = nil, &block)
        raise ArgumentError, "Either provide replacement or block, not both" if replacement && block_given?
        raise ArgumentError, "Must provide either replacement or block" if !replacement && !block_given?

        if block_given?
          contents.gsub!(pattern, &block)
        else
          contents.gsub!(pattern, replacement)
        end

        create_transformation do
          write
        end
        self
      end

      def contents
        if @content_path
          @contents ||= Pathname.new(@content_path).expand_path.read
        else
          @contents ||= @clean_path.read
        end
      end

      private

      def write
        @path.write(contents)
      end

      def cleanup
        @to_delete.each do |path|
          safe_unlink path
        end
        @to_delete.clear
        self
      end

      def reset!
        @dirty = false
        @path = @clean_path.dup
        @contents = nil
        @transformations.clear
        @to_delete.clear
      end

      def apply_transformations!
        @transformations.each do |transformation|
          @dirty = true
          transformation.call(self)
        end
        @path
      end

      def create_transformation(&block)
        @dirty = true
        @transformations << block
      end
    end
  end
end