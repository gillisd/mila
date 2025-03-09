module Mila
  module JSON
    extend self

    @parser ||= Parser.new
    @scanner ||= Scanner.new

    def load(string)
      @parser.parse(string)
    end

    def dump(...)
      @parser.dump(...)
    end

    def scan(...)
      @scanner.scan(...)
    end

    alias_method :parse, :load
    alias_method :generate, :dump
    alias_method :extract, :scan
    alias_method :xtract, :scan
  end
end