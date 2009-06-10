$LOAD_PATH.push(File.dirname(__FILE__) + '/../lib')

require 'open-uri'
require 'fileutils'
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
      instance_variable = "@#{instvar(prop[0])} = '#{prop[1]}'"
      self.instance_eval instance_variable
      logger.debug instance_variable
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
      name.gsub('.', '_')
    end

    def self.parse!(args=ARGV)
      RawRunner.new(args[0], args[1], args[2])
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
end

RAW::RawRunner.parse!