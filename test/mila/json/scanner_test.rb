# frozen_string_literal: true
require 'test_helper'

class ScannerTest < Minitest::Test
  include Support::Fixtures

  def setup
    @subject = Mila::JSON::Scanner.new
  end

  def teardown
    # Do nothing
  end

  def test_foo
    html_doc = load_fixture('json_2.html.gz')
    puts @subject.scan(html_doc)
  end
end
