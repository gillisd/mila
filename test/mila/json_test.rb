# frozen_string_literal: true

require 'test_helper'

module Mila
  class JSONTest < Minitest::Test
    include Support::Fixtures
    def setup
      @test_string = load_fixture('json_2.html.gz')
    end

    def test_parse
      puts Mila::JSON.parse('{"key": "value"}')
    end

    def test_extract
      puts Mila::JSON.extract(@test_string)
    end
  end
end
