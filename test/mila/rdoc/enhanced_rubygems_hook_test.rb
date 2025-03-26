# frozen_string_literal: true

require 'test_helper'

module Mila
  class EnhancedRubygemsHookTest < Minitest::Test
    include Support::Fixtures

    class DownloadedFile < SimpleDelegator
      def initialize(pathlike, download_dir:)
        @download_dir = Pathname(download_dir)
        super Pathname(pathlike)
      end

      def to_s
        relative_path.to_path
      end

      alias to_path to_s

      def root_dir
        @download_dir
      end

      def relative_path
        relative_path_from(@download_dir)
      end
    end

    class EnhancedPackage < SimpleDelegator
      def initialize(package)
        super
        @new_spec = spec.clone
      end

      def package
        __getobj__
      end

      def add_extra_rdoc_files
        needed_files = available_docs + downloaded_docs - spec_documentable_files
        @new_spec.extra_rdoc_files += needed_files.map(&:to_s)
        self.spec = @new_spec
      end

      def has_ancestor?(file, dir)
        file.ascend
            .to_a
            .include?(dir)
      end

      def download_dir
        @download_dir ||= Pathname(Dir.mktmpdir)
      end

      def spec_documentable_files
        spec_extra_rdoc_files + spec_source_files
      end

      def spec_extra_rdoc_files
        spec.extra_rdoc_files
            .map { Pathname.new(_1) }
            .flatten
      end

      def spec_source_files
        source_paths = spec.source_paths
                           .map { Pathname(_1) }
        spec.files
            .map { Pathname(_1) }
            .select { |path|
              path.ascend
                  .to_a
                  .then { _1 & source_paths }
                  .any?
            }
            .flatten
      end

      def available_docs
        contents.map { Pathname.new(_1) }
                .select { _1.extname in /rdoc|md/i }
      end

      def downloaded_docs
        @downloaded_docs ||= (
          find_unpackaged_docs
            .map { Pathname(_1) }
            .select { has_ancestor?(_1, download_dir) }
            .map { DownloadedFile.new(_1, download_dir: download_dir) }
        )
      end

      def repo_path
        repo_from_homepage || repo_from_metadata
      end

      def find_unpackaged_docs
        grab_script_path = Mila.root.join('../', 'bin', 'grab')
        raise NameError, "grab script not found at #{grab_script_path.to_path}" unless grab_script_path.exist?
        dir = download_dir

        globs = '**/*.rdoc **/*.md README Readme LICENSE CHANGELOG HISTORY'
        split_globs = Shellwords.shellsplit(globs)
        cmd = Array.new
        cmd << grab_script_path.to_path.to_s
        cmd << "--output-dir"
        cmd << dir.to_s
        cmd << repo_path.to_s
        cmd += split_globs.map { "\"#{_1}\"" } # Ensure proper quoting of paths
        puts "Running command: #{cmd.join(' ')}"
        system(*cmd)

        remote_docs = dir.glob(split_globs)
                         .map { _1.relative_path_from(dir) }
        missing_docs = (remote_docs - available_docs)
                         .map { dir.join _1 }
                         .map(&:to_path)
        missing_docs
      end

      private

      def repo_from_metadata
        spec.metadata
            .values
            .map { URI.parse(_1) }
            .select { _1.host == 'github.com' }
            .select { _1.path in %r{^/[^/]+/[^/]+$} }
            .map { parse_repo(_1) }
            .first
            .to_s
      end

      def repo_from_homepage
        uri = URI.parse(spec.homepage)
        parse_repo(uri)
      end

      def parse_repo(uri)
        return nil unless uri.host == 'github.com'
        uri.path
           .then { Pathname(_1) }
           .then {
             _1.dirname
               .basename
               .join(_1.basename)
           }
      end
    end

    def test_install_rake

      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        with_fixture 'rake-13.2.1.gem' do |f|
          f.size
          package = Gem::Package.new(f.path)
          enhanced_package = EnhancedPackage.new(package)
          # enhanced_package.add_extra_rdoc_files
          # assert_equal 8, enhanced_package.spec.extra_rdoc_files.count

          installer = Gem::Installer.new(
            enhanced_package,
            install_dir: dir.to_path
          )
          installer.install
          install_dir = dir.join('gems/rake-13.2.1')
          assert_path_exists install_dir
          assert_path_exists install_dir.join('lib/rake.rb')

          doc_dir = dir.join('doc/rake-13.2.1')
          refute_path_exists doc_dir

          keys_to_unset = (ENV.to_h.keys - Bundler.unbundled_env.keys)
          command = keys_to_unset.inject(StringIO.new) do |io, key|
            io.write "unset #{key}; "
            io
          end
          command.write "export GEM_HOME=#{dir.to_path}; "
          command.write "export GEM_PATH=#{dir.to_path}; "
          command.write "env; "
          command.write "gem install rdoc --no-document; "
          command.write "gem rdoc --ri --rdoc rake"
          FileUtils.chdir(dir) do
            system command.string
            assert_path_exists doc_dir

            puts doc_dir.join('ri').glob('**/*.ri').count
            puts doc_dir.join('rdoc').glob('**/*.html').count
            # assert_equal 295, doc_dir.join('ri').glob('**/*.ri').count
            # assert_equal 56, doc_dir.join('rdoc').glob('**/*.html').count
          end
        end
      end
    end

    def test_install_sequel
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        with_fixture 'sequel-5.90.0.gem' do |f|
          f.size
          package = Gem::Package.new(f.path)
          enhanced_package = EnhancedPackage.new(package)
          enhanced_package.add_extra_rdoc_files
          assert_equal 34, enhanced_package.spec.extra_rdoc_files.count

          installer = Gem::Installer.new(
            enhanced_package,
            install_dir: dir.to_path
          )
          installer.install

          install_dir = dir.join('gems/sequel-5.90.0')
          assert_path_exists install_dir
          assert_path_exists install_dir.join('lib/sequel.rb')

          enhanced_package.downloaded_docs
                          .each do |file|
            target_path = install_dir.join(file.relative_path)
            FileUtils.mkdir_p target_path.dirname
            FileUtils.ln_s(file.expand_path, target_path)
          end

          doc_dir = dir.join('doc/sequel-5.90.0')
          refute_path_exists doc_dir

          keys_to_unset = (ENV.to_h.keys - Bundler.unbundled_env.keys)
          command = keys_to_unset.inject(StringIO.new) do |io, key|
            io.write "unset #{key}; "
            io
          end
          command.write "export GEM_HOME=#{dir.to_path}; "
          command.write "export GEM_PATH=#{dir.to_path}; "
          command.write "env; "
          command.write "gem install rdoc --no-document; "
          command.write "gem rdoc --ri --rdoc sequel"
          FileUtils.chdir(dir) do
            system command.string
            assert_path_exists doc_dir

            assert_equal 5790, doc_dir.join('ri').glob('**/*.ri').count
            assert_equal 777, doc_dir.join('rdoc').glob('**/*.html').count
            doc_dir
          end
        end
      end
    end
  end
end
