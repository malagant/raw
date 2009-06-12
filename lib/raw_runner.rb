$LOAD_PATH.push(File.dirname(__FILE__) + '/../lib')

require 'open-uri'
require 'fileutils'
require 'optparse'
require 'raw'

module RAW
  class RawRunner < RAW::AntProject
    attr_reader :root
    attr_writer :logger

    def initialize(template, root = '', options = {})
      super(options)
      @targets = Hash.new
      logger = options[:logger] || Logger.new(STDOUT)
      @logger.level = options[:loglevel] || Logger::INFO
      @root = File.expand_path(File.directory?(root) ? root : File.join(Dir.pwd, root))

      if template
        logger.info("applying script #{template}")

        load_script(template)

        logger.info"applied script #{template}"
      else
        logger.info"no script applied#{template}"
      end
    end

    # defines a property in ant and also an instance variable
    def property(options)
      name = options[:name]
      file = options[:file]
      environment = options[:environment]

      method_missing(:property, options)

      if name
        build_instance_variable([name, options[:location] || options[:value]])
      elsif file || environment
        build_properties
      else
        logger.debug options.inspect
        raise "No name or file attribute given for property!"
      end
    end

    def property_value(name)
      project.get_property(name)
    end

    def build_instance_variable(prop)
      begin
      instance_variable = "@#{instvar(prop[0])} = '#{prop[1]}'"
      self.instance_eval instance_variable
      logger.debug instance_variable
      rescue SyntaxError => e
        logger.error "Problem with #{instance_variable}. Cannot create valid instance variable."
        raise e
      end
    end

    def build_properties
      project.properties.each do |prop|
        build_instance_variable(prop)
      end
      logger.debug instance_variables
      # TODO: Hack
      @ant_version = RAW::ApacheAnt::Main.ant_version[/\d\.\d\.\d/].to_f
    end

    def instvar(name)
      name = name.gsub('.', '_')
      name.gsub('-', '_')
    end


    def load_script(template)
      begin
        code = open(template).read

        self.instance_eval(code)
      rescue LoadError, Errno::ENOENT => e
        raise "The script #{template} could not be loaded. Error: #{e}"
      end
    end

    def target(name, depends = [], &block)
      @targets[name] = block
    end

    def build(task)
      block = @targets[task]
      block.call
    end
  end

  class RawTool
    def parse!(args)
      if args.length == 0
        puts options
      elsif args.length == 1 && args[0] == ('-h' || '--help')
        options.parse!(args)
      else
        general, sub = split_args(args)
        options.parse!(args)

        if general.empty?
          puts options
        else
          @root_dir = '.' if @root_dir.nil?
          RawRunner.new(general[0], @root_dir, {})
        end
      end
    end

    def split_args(args)
      left = []
      while args[0] and args[0] =~ /^-/ do
        left << args.shift
      end
      left << args.shift if args[0]
      return [left, args]
    end

    def self.parse!(args=ARGV)
      RawTool.new.parse!(args)
    end

    # Options and how they are used
    def options
      OptionParser.new do |o|
        o.set_summary_indent('  ')
        o.banner =    "Usage: raw raw-script-url [OPTIONS]"
        o.define_head "Ruby ANT Wrapper (RAW)."

        o.separator ""
        o.separator "GENERAL OPTIONS"

        o.on("-v", "--verbose", "Turn on verbose ant output.") { |verbose| $verbose = verbose }
        o.on("-h", "--help", "Show this help message.") { puts o; exit }
        o.on("-r", "--root directory", "Set the root path of the script. Defaults to '.'") { |root| @root_dir = root}
        o.on("-l", "--loglevel level", "Set the log level. Default is info. Possible values are: error, warn, info, debug") { |level| @loglevel = level}

        o.separator ""
        o.separator "EXAMPLES"
        o.separator "  run example script:"
        o.separator "    raw scripts/ant.rb -r ../.. -v \n"
        o.separator "  Run a raw-script from a pastie URL:"
        o.separator "    raw http://www.pastie.org/508302 -r ../.. -v -l debug \n"
        o.separator "  Run a script without parameters:"
        o.separator "    raw ant.rb\n"
      end
    end
  end
end

RAW::RawTool.parse!