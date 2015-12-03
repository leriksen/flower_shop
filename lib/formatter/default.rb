require 'active_support/inflector'
require 'fcntl'

class Formatter
  class Default

    # we want to cater for 3 different scenarios
    # 1. we get an IO object directly
    # 2. we get an string representing an IO object, like 'STDOUT', that responds to puts
    # 3. we get a file name
    def initialize(drain)
      # case 1 - first check if its an actual IO object already
      if drain.respond_to?(:puts)
        @drain = drain
      else
        # case 2 - next check if its a string that can be turned into an IO, held in a constant
        begin
          io = drain.constantize
          if io.respond_to?(:puts)
            @drain = io
          end
        rescue NameError => e # cant be constantized, fall through to ensure
        rescue => e # something else wrong - re-raise
          raise BadFormatterError, e.message
        ensure
          # case 3 - checks show it is not an IO object of any form, treat the drain as a filename
          unless @drain
            @drain = File.open drain, Fcntl::O_RDWR|Fcntl::O_CREAT|Fcntl::O_TRUNC
          end
        end
      end
    end

    def format(type, amount, price, components=[])
      # possible for a bad order file (with unfulfillable order) to have nil as components
      # report as such
      if components
        @drain.puts "#{amount} #{type} $#{sprintf("%0.2f", price/100.0)}"
        components.each do |component|
          @drain.puts "       #{component[0]} x #{component[1]} $#{sprintf("%0.2f", component[2]/100.0)}"
        end
      else
        @drain.puts "unfulfillable order for #{amount} #{type}"
      end
    end

    class BadFormatterError < StandardError; end
  end
end
