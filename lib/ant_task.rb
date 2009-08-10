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

module RAW
  class AntTask
    attr_accessor :unknown_element, :project, :taskname, :logger, :executed

    public
    # Creates an AntTask
    # taskname 
    #   -A String representing the name of an Ant Task. This name should correspond to 
    #   the element name of the Ant xml task (e.g. javac, jar, war, etc).
    # antProject
    #   -An instance of an AntProject
    # attributes
    #   -A Hash of task name/values to be applied to the task.
    #   
    # For example:
    #   antProject = AntProject.new()
    #   antTask = AntTask.new('javac', antProject, {:debug => 'on', :verbose => 'no', :fork => 'no'})     
    def initialize(taskname, antProject, attributes)

      taskname = taskname[1, taskname.length-1] if taskname[0, 1] == "_"
      @logger = antProject.logger
      @taskname = taskname
      @project_wrapper = antProject
      @project = antProject.project
      @logger.debug(antProject.to_s)
      @unknown_element = create_unknown_element(@project, taskname)
      @logger.debug(to_s)

      add_attributes(attributes)

    end

    # Displays the Class name followed by the Task name
    # -e.g.  AntTask[javac]
    def to_s
      return self.class.name + "[#{@taskname}]"
    end

    def create_unknown_element(project, taskname)

      element = ApacheAnt::UnknownElement.new(taskname)
      element.project = project
      element.owning_target = ApacheAnt::Target.new
      element.task_name = taskname

      #DNR. This initializes the Task's Wrapper object and prevents NullPointerExeption upon execution of the task
      element.runtime_configurable_wrapper

      if (@project_wrapper.ant_version >= 1.6)
        element.task_type = taskname
        element.namespace = ''
        element.qname = taskname
      end

      return element

    end

    # Sets each attribute on the AntTask instance.
    # :attributes - is a Hash.
    def add_attributes(attributes)

      return if attributes == nil

      wrapper = ApacheAnt::RuntimeConfigurable.new(@unknown_element, @unknown_element.task_name)

      if (@project_wrapper.ant_version >= 1.6)
        attributes.each do |key, val|
          apply_to_wrapper(wrapper, key.to_s, val){ |k, v| wrapper.set_attribute(k, v)}
        end
      else
        @unknown_element.runtime_configurable_wrapper = wrapper
        attribute_list = XmlSax::AttributeListImpl.new()
        attributes.each do |key, val|
          apply_to_wrapper(wrapper, key.to_s, val){ |k, v| attribute_list.add_attribute(k, 'CDATA', v)}
        end
        wrapper.set_attributes(attribute_list)
      end

    end

    def apply_to_wrapper(wrapper, key, value)

      raise ArgumentError, "ArgumentError: You cannot use an Array as an argument. Use the :join method instead; i.e ['file1', 'file2'].join(File::PATH_SEPARATOR)." if value.is_a?(Array)

      begin
        if (key == 'pcdata')
          wrapper.add_text(value.to_s)
        else
          yield key, value.to_s
        end
      rescue StandardError
        raise ArgumentError, "ArgumentError: Unable to set :#{key} attribute with value => '#{value}'"
      end

    end

    # Add <em>child</em> as a child of this task. 
    def add(child)
      @unknown_element.add_child(child.unknown_element())
      @unknown_element.runtime_configurable_wrapper.add_child(child.unknown_element().runtime_configurable_wrapper)
    end

    # Invokes the AntTask. 
    def execute
      @unknown_element.maybe_configure
      @unknown_element.execute
      build_instance_variable(@unknown_element.wrapper)
      @executed = true
      return nil
    end

    private

    def build_instance_variable(wrapper)
      variable = wrapper.attributeMap.get('property')

      if variable
        logger.debug "creating variable = @#{variable} with value #{@project_wrapper.property_value(variable.to_s)}"
        unless @project_wrapper.instance_variable_defined? "@#{variable.to_s}".to_sym
          instance_eval <<-END
            @project_wrapper.instance_variable_set(:@#{@project_wrapper.instvar(variable)}, @project_wrapper.property_value(variable.to_s))
          END
        end
      end
    end

  end
end