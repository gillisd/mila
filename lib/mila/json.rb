module Mila
  module JSON
    extend self

    def load(string)
      parser.parse(string)
    end

    def dump(...)
      parser.dump(...)
    end

    def scan(...)
      scanner.scan(...)
    end

    alias_method :parse, :load
    alias_method :generate, :dump
    alias_method :extract, :scan
    alias_method :xtract, :scan

    private

    def scanner
      @scanner ||= Scanner.new
    end

    def parser
      @parser ||= Parser.new
    end
  end
end