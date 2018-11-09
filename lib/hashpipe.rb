require 'hashpipe/version'
require 'ruby_parser'
require 'ruby2ruby'

module Hashpipe
  class Formatter
    include Enumerable

    def initialize(string)
      @parser = RubyParser.new
      @r2r    = Ruby2Ruby.new
      @hash   = parse(string)
    end
    
    def to_18
      "{%s}" % map {|a| a.join(' => ')}.join(', ')
    end

    def to_19
      "{%s}" % map {|a| format_pair(*a)}.join(', ')
    end

    def to_multiline
      "{\n%s\n}" % map {|(k, v)| "  #{pad(k).red.bold} => #{v.green}"}.join(",\n")
    end

    def each
      return to_enum unless block_given?
      @hash.map {|a| yield a.map(&method(:to_ruby))}
    end

    private

    def format_pair(k, v)
      if k =~ /\A:[a-z0-9A-Z]+\z/
        "%s: %s" % [k[1..-1], v]
      else
        "%s => %s" %  [k, v]
      end
    end

    # Add left padding
    def pad(key)
      "%-#{max}s" % key
    end

    # Find max length of line for padding
    def max
      @max ||= map {|a| a[0].length}.max
    end

    def to_ruby(sexp)
      sexp = sexp.deep_clone
      @r2r.process(sexp)
    end

    # Handle exceptions
    def parse(string)
      sexp = @parser.process(string)
      raise "Not a hash." unless sexp.shift == :hash
      Hash[*sexp]
    end
  end

  # Add Colorization Swag
  class String
    def colorize(color_code)
      "\e[#{color_code}m#{self}\e[0m"
    end

    def red
      colorize(31)
    end

    def green
      colorize(32)
    end

    def bold
      "\e[1m#{self}\e[22m"
    end
  end
end
