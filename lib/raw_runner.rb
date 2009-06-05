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
      @logger = options[:logger] || Logger.new(STDOUT)
      @logger.level = options[:loglevel] || Logger::INFO
      @root = File.expand_path(File.directory?(root) ? root : File.join(Dir.pwd, root))
      log(@logger.level, "applying script #{template}")

      load_script(template)

      log Logger::INFO, "applied script #{template}"
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

    def log(severity = Logger::INFO, message = '')
      case severity
        when Logger::INFO
          @logger.info(message)
        when Logger::ERROR
          @logger.error(message)
        when Logger::WARN
          @logger.warn(message)
        when Logger::DEBUG
          @logger.debug(message)
      end
    end
  end
end

raw = RAW::RawRunner.new("../scripts/j_ruby_build_file.rb", ".", :loglevel => Logger::DEBUG)
puts raw.to_s