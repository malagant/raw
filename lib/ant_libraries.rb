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

module RAW
  module ApacheAnt
    DefaultLogger = RjbAdapter.import_class("org.apache.tools.ant.DefaultLogger")
    Main = RjbAdapter.import_class("org.apache.tools.ant.Main")
    Project = RjbAdapter.import_class("org.apache.tools.ant.Project")
    RuntimeConfigurable = RjbAdapter.import_class("org.apache.tools.ant.RuntimeConfigurable")
    Target = RjbAdapter.import_class("org.apache.tools.ant.Target")
    UnknownElement = RjbAdapter.import_class("org.apache.tools.ant.UnknownElement")
  end
  
  module JavaLang
    System = RjbAdapter.import_class("java.lang.System")
  end
  
  module XmlSax
    AttributeListImpl = RjbAdapter.import_class("org.xml.sax.helpers.AttributeListImpl")
  end
end