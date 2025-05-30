# frozen_string_literal: true

require 'test_helper'

class Rake::EditableFileTest < Minitest::Test
  attr_reader :env
  include FileUtils
  EditableFile = ::Mila::Rake::EditableFile

  def setup
    @env = Support::Rake::Env.new
    @env.mkdir_p 'lib'
    @env.start
  end

  def teardown
    @env.stop
  end

  def test_basic_editable_file
    env.touch_file 'script.rb', "class Foo\n  def bar\n    puts 'Hello, world!'\n  end\nend\n"

    assert_path_exists env.workdir.join('script.rb')
    f = EditableFile.new(env.workdir.join('script.rb'))
    f.basename = 'different.rb'
    f.save

    assert_path_exists env.workdir.join('different.rb')
    refute_path_exists env.workdir.join('script.rb')
  end

  def test_rename_basename
    env.touch_file 'script.rb', "class Foo\n  def bar\n    puts 'Hello, world!'\n  end\nend\n"
    assert_path_exists env.workdir.join('script.rb')
    env.mkdir_p 'dest'
    assert_path_exists env.workdir.join('dest')

    Mila::Rake::CopyTask.new :test_copy do |t|
      t.description = 'Test copy task'
      t.root_dir = env.workdir.to_s
      t.destination_dir = env.workdir.join('dest').to_s
      t.before_copy { |f| f.basename = 'foo.rb' }
      t.include 'script.rb'
    end

    Rake::Task[:test_copy].invoke

    assert_path_exists env.workdir.join('dest/foo.rb')
    refute_path_exists env.workdir.join('dest/script.rb')
  end

  def test_modify_contents
    env.touch_file 'script.rb', "class Foo\n  def bar\n    puts 'Hello, world!'\n  end\nend\n"
    assert_path_exists env.workdir.join('script.rb')
    env.mkdir_p 'dest'
    assert_path_exists env.workdir.join('dest')

    Mila::Rake::CopyTask.new :test_copy do |t|
      t.description = 'Test copy task'
      t.root_dir = env.workdir.to_s
      t.destination_dir = env.workdir.join('dest').to_s
      t.before_copy { |f| f.gsub! 'Foo', 'Bar' }
      t.include 'script.rb'
    end

    Rake::Task[:test_copy].invoke

    assert_path_exists env.workdir.join('dest/script.rb')
    assert_match /class Bar/, env.workdir.join('dest/script.rb').read
  end
end
