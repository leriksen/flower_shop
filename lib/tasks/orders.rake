desc "Run the order file - order file is a mandatory parameter"
task :order_runner, [:order_file, :control_file] do |task, args|
  args = args.to_h # dont need the specialised Rake::TaskArguments
  order_file   = args.fetch(:order_file, nil)
  raise "Must supply the path to the order file" unless order_file

  control_file = args.fetch(:control_file, 'config/control.yaml')

  set_logging
  
  Runner.new(order_file, control_file).run
end

$LOAD_PATH << 'lib'

# load all classes under lib/**
Rake::FileList.new("lib/**/*.rb") do |list|
  list.exclude(/tasks/)
end.pathmap("%{^lib/,}X").each {|f| require f}

def set_logging
  require 'logger'

  logger = Logger.new(STDOUT)
  logger.level = Logger.const_get(ENV['LOGLEVEL'] || 'FATAL')

  # need to use send, as 'def' is a scope gate
  Kernel.send :define_method, :logger do
    logger
  end
end