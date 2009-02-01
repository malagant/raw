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

$LOAD_PATH.push(FileUtils::pwd + '/lib')
require 'rubygems'
require 'hoe'
require 'lib/raw'
require 'rake/testtask'

def apply_default_hoe_properties(hoe)
  hoe.remote_rdoc_dir = ''
  hoe.rubyforge_name = 'raw'
  hoe.author = 'Michael Johann'
  hoe.email = 'malagant1969@gmail.com'
  hoe.url = 'http://kenai.com/projects/raw/'
  hoe.summary = 'A Ruby module that wraps the Apache Ant build tool. 
                 RAW can be used to invoke Ant Tasks from a Ruby or a JRuby script.'
  hoe.description = hoe.paragraphs_of('README', 2..5).join("\n\n")
  # hoe.changes = hoe.paragraphs_of('HISTORY', 0..1).join("\n\n")
  puts "Current changes in this release_______________ "
  puts "#{hoe.changes}"
  puts "----------------------------------------------"
end

# builds the MRI Gem
Hoe.new('raw', RAW::VERSION) do |hoe|
  apply_default_hoe_properties hoe
  hoe.extra_deps << ["rjb", ">= 1.0.3"]
end

#builds the JRuby Gem
Hoe.new('raw', RAW::VERSION) do |hoe|
  apply_default_hoe_properties hoe
  hoe.spec_extras = { :platform => 'java' }
end

Rake::TestTask.new('test') do |t|
  t.ruby_opts = ['-r test/load_devcreek.rb']
  t.test_files = ['test/*test.rb']
end
