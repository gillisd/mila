# frozen_string_literal: true

# We define the following two similar name classes in this file:
#
# - RDoc::RubyGemsHook
# - RDoc::RubygemsHook
#
# RDoc::RubyGemsHook is the main class that has real logic.
#
# RDoc::RubygemsHook is a class that is only for
# compatibility. RDoc::RubygemsHook is used by RubyGems directly. We
# can remove this when all maintained RubyGems remove
# `rubygems/rdoc.rb`.

module Mila
  module RDoc
    class EnhancedRubyGemsHook < ::RDoc::RubyGemsHook
      def initialize(spec, generate_rdoc = nil, generate_ri = nil)
        super
        spec
      end
    end
  end
end