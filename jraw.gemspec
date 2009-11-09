Gem::Specification.new do |s|
  s.name = %q{jraw}
  s.version = "0.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Johann"]
  s.date = %q{2009-08-10}
  s.default_executable = %q{jraw}
  s.description = %q{JRAW is a Ruby ANT Wrapper for describing Apache ANT tasks in ruby instead of XML.}
  s.email = %q{mjohann@rails-experts.com}
  s.executables = ["jraw"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README", "LICENSE"]
  s.files = ["History.txt", "Manifest.txt", "README", "LICENSE", "Rakefile", "bin/jraw", "lib/ant_libraries.rb", "lib/ant_project.rb", "lib/ant_task.rb", "lib/jraw.rb", "lib/jraw_runner.rb", "lib/rjb_adapter.rb", "lib/jraw_utilities.rb", "spec/javaadapter_spec.rb", "spec/jraw_antproject_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://kenai.com/projects/raw}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{JRAW is a Ruby ANT Wrapper for describing Apache ANT tasks in ruby instead of XML.}
  s.test_files = ["spec/javaadapter_spec.rb", "spec/jraw_antproject_spec.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0.7.3"])
    else
      s.add_dependency(%q<rake>, [">= 0.7.3"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.7.3"])
  end
end