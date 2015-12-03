class Syntax
  class Default
    # this syntax matcher expects lines of the form "XDD D+" - everything else raises
    def self.process(line)
      fields = line.split
      if fields.length > 2
        raise BadOrderFormatError, "line does not match the require format of 'type amount' - #{line}"
      end

      raise BadOrderFormatError, "bad amount field #{fields[0]}" unless fields[0] =~ /^\d+$/
      raise BadOrderFormatError, "bad type field #{fields[1]}"   unless fields[1] =~ /^[A-Z]\d\d$/

      [fields[0].to_i, fields[1]]
    end

    class BadOrderFormatError < StandardError; end
  end
end

class Parser
  class Default

    include Enumerable

    def initialize(io, syntax=Syntax::Default)
      # returns raw enumerator
      @io = io.each
      @syntax = syntax
    end

    def each
      loop do
        yield process_line(io.next)
      end
    end

    private
    def process_line(line)
      syntax.process(line)
    end

     attr_reader :io, :syntax
  end
end