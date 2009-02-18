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