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


# ATTENTION!!!!! This is just experimental and definitly not working ;)
# Please don't try this peace of s***

require 'raw'
require 'rexml/document'

class BuildFileConverter
  def initialize(path)
    doc = File.new(path)
    doc_root = REXML::Document.new(doc)

    ant_project = generate_project(doc_root.root)
    children = doc_root.root.elements
    descriptions = children.collect 'description'
    targets = children['target']

    puts descriptions
    puts targets
  end

  def generate_project(project)
    puts "@ant_project = RAW::AntProject.new(#{extract_options(project.attributes)})"
  end

  private

  def extract_options(hash_object)
    content = "{ "
    hash_object.each_attribute do |attr|
      content << ":#{attr.expanded_name} => '#{attr.value}', "
    end
    content.chomp(", ") << " }"
  end
end

doc_root = BuildFileConverter.new('/Users/mjohann/projects/jruby/build.xml')