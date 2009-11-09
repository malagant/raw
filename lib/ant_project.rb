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

module JRAW
  class AntProject
    require 'logger'
    require 'ant_task'

    @@classes_loaded = false

    # Here we go: Let's define some attributes
    public
    # getter and setter for the project instance,
    # the logger, the declarative and the attribute ant_version
    attr_accessor :project, :logger, :ant_version, :declarative, :default_target

    # Create an AntProject. Parameters are specified via a hash:
    # :ant_home => <em>Ant basedir</em>
    #   -A String indicating the location of the ANT_HOME directory. If provided, JRAW will
    #   load the classes from the ANT_HOME/lib dir. If ant_home is not provided, the ANT jar files
    #   must be available on the CLASSPATH.
    # :name => <em>project_name</em>
    #   -A String indicating the name of this project.
    # :basedir => <em>project_basedir</em>
    #   -A String indicating the basedir of this project. Corresponds to the 'basedir' attribute
    #   on an Ant project.
    # :declarative => <em>declarative_mode</em>
    #   -A boolean value indicating wether ANT tasks created by this project instance should
    #   have their execute() method invoked during their creation. For example, with
    #   the option :declarative => <em>true</em> the following task would execute;
    #   @antProject.echo(:message => "An Echo Task")
    #   However, with the option :declarative => false, the programmer is required to execute the
    #   task explicitly;
    #   echoTask = @antProject.echo(:message => "An Echo Task")
    #   echoTask.execute()
    #   Default value is <em>true</em>.
    # :logger => <em>Logger</em>
    #   -A Logger instance. Defaults to Logger.new(STDOUT)
    # :loglevel => <em>The level to set the logger to</em>
    #   -Defaults to Logger::ERROR
    # This is for further initializations inside the constructor
    # and must be called once from the users ANT script
    # Example usage:
    # init_project :basedir => '/Users/mjohann/projects/jruby_jraw',
    #         :name => 'JRuby',
    #         :default => 'jar',
    #         :anthome => ANT_HOME
    def init_project(options)
      # The ANT version used
      logger.info JRAW::ApacheAnt::Main.ant_version
      @ant_version = JRAW::ApacheAnt::Main.ant_version[/\d\.\d\.\d/].to_f
      # instance of ANT project
      @project = JRAW::ApacheAnt::Project.new
      # The default project name taken from the options hash or left blank
      @project.name = options[:name] || ''
      # The default ANT target taken from the options hash or left blank
      @project.default = ''
      # The project's base directory taken from the options hash or the current working directory
      @project.basedir = options[:basedir] || FileUtils::pwd
      # intializing the ANT project
      @default_target = options[:default] if options[:default]
      logger.debug "Default == #{options[:default]}"
      @project.init

      # Sets the task definitions to be declared only or they get executed directly
      # Default is true
      unless options[:declarative]
        logger.debug("declarative is nil")
        self.declarative = true
      else
        logger.debug("declarative is #{options[:declarative]}")
        self.declarative = options[:declarative]
      end

      # Here we setup the default logger instance
      default_logger = ApacheAnt::DefaultLogger.new
      default_logger.message_output_level = Logger::INFO
      # Output is either Standard out or the stream in options hash
      default_logger.output_print_stream = options[:outputstr] || JavaLang::System.out
      default_logger.error_print_stream = options[:errorstr] || JavaLang::System.err
      # Output will be like in log4j.properties configured
      default_logger.emacs_mode = false
      # Set the default logger as the build listener
      @project.add_build_listener(default_logger)
    end

    # Constructor will be called internally and consumes
    # the options hash which can contain infos about a logger  
    def initialize(options)
      @logger = options[:logger] || Logger.new(STDOUT)
      logger.level = options[:loglevel] || Logger::INFO

      @task_stack = Array.new
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
      @ant_version = JRAW::ApacheAnt::Main.ant_version[/\d\.\d\.\d/].to_f
    end

    def instvar(name)
      name = name.gsub('.', '_')
      name.gsub('-', '_')
    end

    
    def method_missing(sym, *args)
      begin
        task = AntTask.new(sym.to_s, self, args[0])

        parent_task = @task_stack.last
        @task_stack << task

        yield self if block_given?

        parent_task.add(task) if parent_task

        if @task_stack.nitems == 1
          if declarative == true
            @logger.debug("Executing #{task}")
            task.execute
          else
            @logger.debug("Returning #{task}")
            return task
          end
        end

      rescue
        @logger.error("Error instantiating '#{sym.to_s}' task: " + $!)
        raise
      ensure
        @task_stack.pop
      end

    end

    #The Ant AntProject's name. Default is ''
    def name
      return @project.getName
    end

    #The Ant AntProject's basedir. Default is '.'
    def basedir
      return @project.base_dir.absolute_path;
    end

    #Displays the Class name followed by the AntProject name
    # -e.g.  AntProject[BigCoProject]
    def to_s
      return self.class.name + "[#{name}]"
    end

  end
end