require 'yaml'
require 'active_support/inflector'

# reads a YAML control file, and uses it to construct some class constants,
# and data methods.
# Class constants must already exist, loaded from library file, via the autoload mechanism defined in the 
# runner rake file
class Controller
  def initialize(control_file)
    begin
      @cf = YAML.load_file(control_file)
    rescue StandardError => e
      raise BadControlFileError, e.message
    end

    build_resources
  end

  class BadControlFileError < StandardError; end

  private
  attr_reader :cf

  def build_resources
    @cf.each do |base, val|
      # we will create a Base::Impl constant
      # and a base_data() method from the yaml data
      base_klass = base.camelize
      impl = val.fetch('strategy', 'default')
      impl_klass = impl.camelize

      # not all controllers have data
      data = val.fetch('data', nil)

      # only parsers support syntax - how to lex a line
      syntax = val.fetch('syntax', nil)

      # we will need to load the class, before
      # creating the constant, simpler than
      # doing the Object.const_set(...) dance.
      # note that these need to be defined, before
      # they get used in a control yaml file.
      # we wrap in a begin-rescue-end block and
      # try to help abusers with a reminder to create
      # the strategy class first
      begin
        require "#{base}/#{impl}"
      rescue LoadError
        raise BadControlFileError, "could not find a file with a definition of #{base_klass}::#{impl_klass}"
      end

      # define our class accessor
      self.class.send :define_method, "#{base}" do
        "#{base_klass}::#{impl_klass}".constantize
      end

      # define our data accessor
      if data
        self.class.send :define_method, "#{base}_data" do
          data
        end
      end

      if syntax
        self.class.send :define_method, "syntax" do
          # do not need to require - the parser and syntax are paired in the same file
          # and hence the namespace constant already exists
          "Syntax::#{syntax.camelize}".constantize
        end
      end
    end
  end
end