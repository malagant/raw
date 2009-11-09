# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations
# under the License.

$LOAD_PATH.push(File.dirname(__FILE__) + '/../lib')

require 'open-uri'
require 'fileutils'
require 'optparse'
require 'jraw'

module JRAW
  class JRawRunner < JRAW::AntProject
    attr_reader :root, :targets

    def initialize(template, root = '', options = {})
      super(options)
      @targets = Hash.new
      @root = File.expand_path(File.directory?(root) ? root : File.join(Dir.pwd, root))

      if template
        logger.info("Applying script #{template}")

        load_script(template)

        # Execute the given target
        if options[:target]
          build options[:target]
          # or find the default and call that
        elsif @default_target
          build @default_target.to_sym
        end

        logger.info"Applied script #{template}"
      else
        logger.info"No script #{template} applied."
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

    def target(name, options = {}, &block)
      target = Target.new(name)
      logger.debug("adding target #{name}")
      if options[:depends]
        if options[:depends].is_a? Symbol
          options[:depends] = [options[:depends]]
        end
        options[:depends].each do |dependancy|
          logger.debug "adding dependancy #{dependancy} to target #{name}"
          target.dependencies << dependancy
        end
      end
      target.block = block
      targets[name] = target
    end

    def build(task)
      block = nil
      block = targets[task].block if targets[task]
      raise "No target named #{task} found." unless block
      targets[task].dependencies.each do |dependency|
        logger.debug("But calling target #{dependency} before")
        build dependency
      end
      logger.info("Calling target #{task}")
      block.call
    end
  end

  # Handles the startup of JRAW with parsing options etc.
  class JRawTool
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
          JRawRunner.new(general[0], @root_dir, {:loglevel => @loglevel, :target => @target})
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
      JRawTool.new.parse!(args)
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
        o.banner =    "Usage: jraw jraw-script-url [OPTIONS]"
        o.define_head "Ruby ANT Wrapper (JRAW)."

        o.separator ""
        o.separator "GENERAL OPTIONS"

        o.on("-v", "--verbose", "Turn on verbose ant output.") { |verbose| $verbose = verbose }
        o.on("-h", "--help", "Show this help message.") { puts o; exit }
        o.on("-r", "--root directory", "Set the root path of the script. Defaults to '.'") { |root| $root_dir = root}
        o.on("-l", "--loglevel level", "Set the log level. Default is info. Possible values are: error, warn, info, debug") { |level| @loglevel = loglevel(level)}
        o.on("-t", "--target target", "Target to execute with ANT") { |target| @target = target.to_sym}
        o.separator ""
        o.separator "EXAMPLES"
        o.separator "  run example script:"
        o.separator "    jraw scripts/ant.rb -r ../.. -v \n"
        o.separator "  Run a jraw-script from a pastie URL:"
        o.separator "    jraw http://www.pastie.org/508302 -r ../.. -v -l debug \n"
        o.separator "  Run a script without parameters:"
        o.separator "    jraw ant.rb\n"
      end
    end
  end
end

JRAW::JRawTool.parse!