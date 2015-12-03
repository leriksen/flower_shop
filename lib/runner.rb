require 'fcntl'

class Runner
  def initialize(order_file, control_file)

    check_files order_file, control_file

    @control = build_controller control_file

    @parser    = control.parser.new(File.open(order_file, Fcntl::O_RDONLY), control.syntax)
    @formatter = control.formatter.new(control.formatter_data)
    @pricer    = control.pricer.new(control.pricer_data)
  end

  def run
    begin
      line = 1
      parser.each do |amount, type|
        price, components = pricer.price(type, amount)
        formatter.format(type, amount, price, components)
        line += 1
      end
    rescue control.syntax::BadOrderFormatError => e
      # rethrow the same, but with a bit more info
      raise control.syntax::BadOrderFormatError, "In file @order_file, line #{line}, #{e.message}"
    end
  end

  class NoControlFileError         < StandardError; end
  class UnreadableControlFileError < StandardError; end
  class NoOrderFileError           < StandardError; end
  class UnreadableOrderFileError   < StandardError; end

  private
  attr_reader :parser, :formatter, :pricer, :control

  def check_files(order_file, control_file)

    logger.debug("control_file:#{control_file}")
    logger.debug("order_file:#{order_file}")

    raise(NoOrderFileError, "missing #{order_file}") unless order_file and File.exist?(order_file)
    raise(UnreadableOrderFileError, "unreadable #{order_file}") unless \
      File.readable?(order_file) and \
      File.file?(order_file)

    raise(NoControlFileError, "missing #{control_file}") unless control_file and File.exist?(control_file)
    raise(UnreadableControlFileError, "unreadable #{control_file}") unless \
      File.readable?(control_file) and \
      File.file?(control_file)

    @order_file = order_file
    @control_file = control_file
  end

  def build_controller(control_file)
    begin
      Controller.new(control_file)
    rescue Controller::BadControlFileError => e
      raise UnreadableControlFileError, e.message
    end
  end
end
