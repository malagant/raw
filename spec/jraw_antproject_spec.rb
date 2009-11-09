require File.dirname(__FILE__) + '/spec_helper'

describe JRAW::JRawRunner, 'initialized' do
  before(:each) do
    # Defining the output directory for our specs
    @output_dir = File.join(FileUtils::pwd, 'tmp', 'output')

    # the resource directory with the sources we like to build
    @resource_dir = File.join(FileUtils::pwd, 'resources')

    # The current ant_home of this project
    @ant_home = File.join(@resource_dir, 'apache-ant-1.7.1')

    # The properties for the new AntProject instance
    @ant_proj_props = {
            :name => "jrawTest",
            :basedir => FileUtils::pwd,
            :declarative => true,
            :logger => Logger.new(STDOUT),
            :loglevel => Logger::DEBUG,
            :ant_home => @ant_home
    }

    # Creating the new instance of JRAW::AntProject
    @ant = JRAW::JRawRunner.new(nil, '.', @ant_proj_props)

    if File.exists?(@output_dir)
      FileUtils.remove_dir(@output_dir)
    end
    FileUtils.mkdir_p(@output_dir, :mode => 0775)
  end

  it "should be proper initialized" do
    @ant_proj_props[:name].should eql @ant.name
    FileUtils::pwd.should eql @ant.basedir
    @ant_proj_props[:declarative].should eql @ant.declarative
    @ant_proj_props[:logger].should eql @ant.logger
  end

  it "should be declarative" do
    @ant = JRAW::JRawRunner.new({ :declarative => false,
            :loglevel => Logger::DEBUG,
            :ant_home => @ant_home })
    echo = @ant.echo :message => "JRAW is really cool"
    echo.should_not be_nil

    @ant = JRAW::JRawRunner.new({ :declarative => true,
            :loglevel => Logger::DEBUG,
            :ant_home => @ant_home })

    echo = @ant.echo :message => "JRAW is really cool"
    echo.should be_nil
  end

  it "should not accept arrays as argument to echo target" do
    begin
      @ant.echo( :message => ['This', 'should', 'fail', 'because', 'Arrays', 'are', 'not', 'supported'] )
      add_failure "Arrays not permitted"
    rescue ArgumentError
    end
  end

  it "should return a valid timestamp" do
    tstamp = @ant.tstamp#.create_format({ :property => "TSTAMP_DE", :pattern => "dd.MM.yyyy hh:mm:ss"})
    puts "*** #{tstamp}"
  end

  it "should copy and remove files" do
    file = @output_dir + '/build.xml'
    File.exists?(file).should be_false

    @ant.copy( :file => @resource_dir + '/build.xml',
            :todir => @output_dir)
    File.exists?(file).should be_true

    @ant.delete( :file => file )
    File.exists?(file).should be_false
  end

  it "should unzip antlr" do
    File.directory?(@output_dir + '/ant-antlr').should be_false
    @ant.unzip(:src => @resource_dir + '/apache-ant-1.7.1/lib/ant-antlr.jar', :dest => @output_dir + '/ant-antlr')
    File.exists?(@output_dir + '/ant-antlr/META-INF/MANIFEST.MF').should be_true
  end

  it "should create as jar" do
    File.exists?(@output_dir + '/archive.jar').should be_false
    @ant.property(:name => 'outputdir', :value => @output_dir)
    @ant.property(:name => 'destfile', :value => '${outputdir}/archive.jar')
    @ant.jar( :destfile => "${destfile}",
            :basedir => @resource_dir + '/src',
            :duplicate => 'preserve')

    File.exists?(@output_dir + '/archive.jar').should be_true
  end

  it "should handle pcdata" do
    @ant.echo(:pcdata => "Foobar &amp; <><><>")
  end

  it "should work with makrodef tasks" do

    return if @ant.ant_version < 1.6

    dir = @output_dir + '/foo'

    File.directory?(dir).should be_false

    @ant.macrodef(:name => 'testmacrodef') do |ant|
      ant.attribute(:name => 'destination')
      ant.sequential do
        ant.echo(:message => "Creating @{destination}")
        ant._mkdir(:dir => "@{destination}")
      end
    end
    @ant.testmacrodef(:destination => dir)
    File.directory?(dir).should be_true
  end

  it "should make dir with property" do
    dir = @output_dir + '/foo'

    File.directory?(dir).should be_false

    @ant.property(:name => 'outputProperty', :value => dir)
    @ant.mkdir(:dir => "${outputProperty}")

    File.directory?(dir).should be_true
  end

  it "should make dir with mkdir task" do
    dir = @output_dir + '/foo'

    File.directory?(dir).should be_false

    @ant.mkdir(:dir => dir)

    File.directory?(dir).should be_true
  end

  it "should echo properly" do
    msg = "JRAW is running an echo task"                    
    @ant.echo(:message => msg, :level => 'info')
    @ant.echo(:message => 100000, :level => 'info')
    @ant.echo(:pcdata => 1000)
  end

  it "should run sucessfully a javac task" do
    FileUtils.mkdir(@output_dir + '/classes', :mode => 0775)

    File.exists?(@output_dir + '/classes/foo/bar/FooBar.class').should be_false

    @ant.javac(:srcdir => @resource_dir + '/src',
    :destdir => @output_dir + '/classes',
    :debug => 'on',
    :verbose => 'no',
    :fork => 'no',
    :failonerror => 'yes',
    :includes => 'foo/bar/**',
    :excludes => 'foo/bar/baz/**',
    :classpath => @resource_dir + '/parent.jar')

    File.exists?(@output_dir + '/classes/foo/bar/FooBar.class').should be_true
    File.exists?(@output_dir + '/classes/foo/bar/baz/FooBarBaz.class').should be_false
  end

  it "should run successfully a javac task with property" do
    FileUtils.mkdir(@output_dir + '/classes', :mode => 0775)

    File.exists?(@output_dir + '/classes/foo/bar/FooBar.class').should be_false
    @ant.property(:name => 'pattern', :value => '**/*.jar')
    @ant.property(:name => 'resource_dir', :value => @resource_dir)
    @ant.path(:id => 'common.class.path') do
      @ant.fileset(:dir => '${resource_dir}') do
        @ant.include(:name => '${pattern}')
      end
    end
    puts "Resource dir: #{@resource_dir}"
    @ant.javac(:srcdir => @resource_dir + '/src',
    :destdir => @output_dir + '/classes',
    :debug => true,
    :verbose => true,
    :fork => 'no',
    :failonerror => 'blahblahblah',
    :includes => 'foo/bar/**',
    :excludes => 'foo/bar/baz/**',
    :classpathref => 'common.class.path')

    File.exists?(@output_dir + '/classes/foo/bar/FooBar.class').should be_true
    File.exists?(@output_dir + '/classes/foo/bar/baz/FooBarBaz.class').should be_false
  end

  it "should define a tasdef with custom classpath" do
    @ant.taskdef(:name => 'retro', :classname => 'foo.bar.Parent', :classpath => @resource_dir)
  end

  it "should define property basedir" do
    @ant.property(:name => 'bla', :value => "Hallo")
    project.getProperty('bla').should == "Hallo"
  end

  it "should read and handle build.properties correctly" do
    @ant.property(:file => '../default.build.properties')
    project.get_property("jruby.classes.dir").should == '512M'
  end

  it "should have proper instance variables available" do
    @ant.property(:file => '../default.build.properties')
    @ant.instance_variable_defined?(:@jruby_classes_dir).should be_true    
  end

  # private methods
  private

  def project
    @ant.project
  end
end

