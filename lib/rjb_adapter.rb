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
  module RjbAdapter
    # We test if the RUBY_PLATFORM is 'java'
    # If true we will use JRuby
    # If false we will use Rjb gem
    def is_jruby?
      return Gem.ruby =~ /jruby/
    end

    # Wrapper for import_class from JRuby
    # If we're on JRuby we use normal import_class
    # Otherwise we use Rjb::import
    def import_class(name)
      if is_jruby?
        return import_using_jruby(name)
      else
        return Rjb::import(name)
      end
    end
    # Here we extract the class name from a given String
    # e.g. str = "java.lang.String" -> class_name = "String"
    def extract_class_name(str)
      class_name = str.split(".").last
    end
    # Here we load the files we need
    # When in JRuby, we do a require for each jar in files argument
    # Otherwise we use Rjb::load to load all jars from a path build from files parameter
    def load(files=[], args=[])
      if is_jruby?
        files.each {|jar| require jar }
      else
        Rjb::load(files.join(File::PATH_SEPARATOR), [])
      end
    end
    
    module_function :import_class, :load, :is_jruby?, :extract_class_name

    if is_jruby?
      require 'java'
    else
      require 'rubygems'
      require 'rjb'
    end
    
    private    
    def RjbAdapter.import_using_jruby(name)
      include_class(name) 
      return remove_const(name.scan(/[_a-zA-Z0-9$]+/).last)
    end
  end
end