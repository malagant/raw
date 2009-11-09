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

require 'rjb_adapter'

module JRAW
  # Defining some Java classes for building the ant tasks etc
  module ApacheAnt
    # The default logger
    DefaultLogger = RjbAdapter.import_class("org.apache.tools.ant.DefaultLogger")
    # The main class from Apache ANT
    Main = RjbAdapter.import_class("org.apache.tools.ant.Main")
    # The ANT project class
    Project = RjbAdapter.import_class("org.apache.tools.ant.Project")
    # The ANT RuntimeConfigurable
    RuntimeConfigurable = RjbAdapter.import_class("org.apache.tools.ant.RuntimeConfigurable")
    # The ANT target class
    Target = RjbAdapter.import_class("org.apache.tools.ant.Target")
    # ANT's class for dynamically wrapping taks
    UnknownElement = RjbAdapter.import_class("org.apache.tools.ant.UnknownElement")
  end
  
  module JavaLang
    # Java's System class for access to System.out and System.err
    System = RjbAdapter.import_class("java.lang.System")
  end
end