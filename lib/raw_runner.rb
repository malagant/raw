$LOAD_PATH.push(File.dirname(__FILE__) + '/../lib')

require 'open-uri'
require 'fileutils'
require 'optparse'
require 'raw'

module RAW
  class RawRunner < RAW::AntProject
    attr_reader :root, :targets

    def initialize(template, root = '', options = {})
      super(options)
      @targets = Hash.new
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

    def condition(options)
      property = options[:property]
      environment = options[:value]


      if name
        build_instance_variable([name, options[:location] || options[:value]])
      elsif file || environment
        build_properties
      else
        logger.debug options.inspect
        raise "No name or file attribute given for property!"
      end
      method_missing(:property, options)
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
      targets[name] = block
    end

    def build(task)
      block = targets[task]
      block.call
    end
  end

  # Handles the startup of RAW with parsing options etc.
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
          RawRunner.new(general[0], @root_dir, {:loglevel => @loglevel})
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

    def self.parse!(args = ARGV)
      RawTool.new.parse!(args)
    end

    def loglevel(level)
      case level
        when 'debug'
         Logger::DEBUG
        when 'info'
         Logger::INFO
        when 'warn'
         Logger::WARN
        when 'error'
         Logger::ERROR
        when 'fatal'
         Logger::FATAL
      end
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
        o.on("-r", "--root directory", "Set the root path of the script. Defaults to '.'") { |root| $root_dir = root}
        o.on("-l", "--loglevel level", "Set the log level. Default is info. Possible values are: error, warn, info, debug") { |level| @loglevel = loglevel(level)}
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