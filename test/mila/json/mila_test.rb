# frozen_string_literal: true

require 'test_helper'
require 'strscan'
require 'json'
require 'stringio'

class MilaTest < Minitest::Test
  include Support::Lorem

  def setup
    @json = File.read('test/support/fixtures/json_1.json')
    @json = json_to_embedded_html(@json)
  end

  def teardown
    # Do nothing
  end

  def test_1
    json = File.read('test/support/fixtures/json_2.html')
    json_objects = []

    # Simple approach scanning the entire string
    position = 0
    while position < json.length
      # Find opening brace
      opening_pos = json.index('{', position)
      break unless opening_pos

      # Keep track of nesting level
      level = 1
      pos = opening_pos + 1
      in_string = false
      escape = false
      start_pos = opening_pos

      # Scan character by character
      while level > 0 && pos < json.length
        char = json[pos]

        if escape
          escape = false
        elsif char == '\\'
          escape = true
        elsif char == '"'
          in_string = !in_string
        elsif !in_string
          if char == '{'
            level += 1
          elsif char == '}'
            level -= 1
          end
        end

        pos += 1

        # If we've found a complete JSON object
        if level == 0
          # Extract and parse
          json_str = json[start_pos...pos]
          begin
            parsed = JSON.parse(json_str)
            json_objects << parsed if parsed.is_a?(Hash) && !parsed.empty?
          rescue
            # Not valid JSON
          end
        end
      end

      # Move to next position
      position = opening_pos + 1
    end

    puts "Found #{json_objects.size} JSON objects"

    assert_equal 569, json_objects.size, "Expected 569 JSON objects"
  end
end