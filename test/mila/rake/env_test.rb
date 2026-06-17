require 'minitest'
require 'minitest/autorun'
require 'forwardable'
require '/Users/davidgillis/repos/mila/test/support/rake/env.rb'

# require_relative '../../support/rake'
module Mila
  # module Rake
  class EnvTest < ::Minitest::Test
    include Support

    def setup
      @env = Support::Rake::Env.new
      @env.start
    end

    def teardown
      @env.stop
    end

    def test_foo

      assert true
    end
  end
end
