RESOURCE_DIR = File.join(FileUtils::pwd, '..', 'spec', 'resources')
ANT_HOME = File.join(RESOURCE_DIR, 'apache-ant-1.7.1')

RAW::RAWClassLoader.load_ant_libs ANT_HOME


init_project :basedir => '/Users/mjohann/projects/jruby',
        :name => 'JRuby',
        :logger => Logger.new(STDOUT),
        :loglevel => Logger::DEBUG,
        :default => 'jar',
        :anthome => ANT_HOME

@resource_dir = RESOURCE_DIR
@ant_home = ANT_HOME
@jruby_src = @resource_dir + '/jruby-1.1.6'
@base_dir = '/Users/mjohann/projects/jruby'
@src_dir = 'src'
@test_dir = 'test'
@lib_dir = 'lib'
@spec_dir = @base_dir + '/spec'
@rubyspec_dir = @spec_dir + '/ruby'
@rails_dir = @test_dir + '/rails'
@mspec_dir = @spec_dir + '/mspec'
@rubyspec_1_8_dir = @rubyspec_dir + '/1.8'
@spec_tags_dir = @spec_dir + '/tags'
@build_lib_dir = @jruby_src + '/build_lib'
@dist_dir = 'dist'
@build_dir = @base_dir + '/build'
@classes_dir = @build_dir + '/classes'
@jruby_classes_dir = @classes_dir + '/jruby'
@jruby_openssl_classes_dir = @classes_dir + '/openssl'
@jruby_instrumented_classes_dir = @classes_dir + '/jruby-instrumented'
@test_classes_dir = @classes_dir + '/test'
@docs_dir = 'docs'
@api_docs_dir = @docs_dir + '/api'
@release_dir = 'release'
@test_results_dir = @build_dir + '/test-results'
@html_test_results_dir = @test_results_dir + '/html'
@html_test_coverage_results_dir = @test_results_dir + '/html-coverage'
@javac_version = '1.5'
@jruby_compile_memory = '256M'
@jruby_launch_memory = '512M'
@jruby_test_memory = '512M'
@jruby_test_jvm = 'java'

property(:name => 'basedir', :value => @base_dir)
property(:name => 'build_lib_dir', :value => @build_lib_dir)
             
# include BuildProperties
# <description>JRuby is a pure Java implementation of a Ruby interpreter.</description>
# JRuby is a pure Java implementation of a Ruby interpreter.
# <!-- First try to load machine-specific properties. -->
# <property file="build.properties"/>
property( :file => 'build.properties')
# <!-- Load revision number for the ruby specs, in a known good state.
#     There should be no spec failures with such revision. -->
# <property file="rubyspecs.revision"/>
property( :file => 'rubyspecs.revision')
# <!-- And then load the defaults. It seems backwards to set defaults AFTER
#     setting local overrides, but that's how Ant works. -->
# <property file="default.build.properties"/>
property( :file => 'default.build.properties')
# <path id="build.classpath">
#  <fileset dir="${build.lib.dir}" includes="*.jar"/>
#  <fileset dir="${lib.dir}" includes="bsf.jar"/>
# </path>
path( :id => 'build.classpath') do
  fileset( :dir => '${build_lib_dir}', :includes => '*.jar')
  fileset( :dir => @lib_dir, :includes => 'bsj.jar')
end
# <property name="emma.dir" value="${build.lib.dir}" />
property( :name => 'emma.dir', :value => @build_lib_dir)
# <path id="emma.classpath">
#  <pathelement location="${emma.dir}/emma.jar" />
#  <pathelement location="${emma.dir}/emma_ant.jar" />
# </path>
path(:id => 'emma.classpath') do
  pathelement(:location => '${emma.dir}/emma.jar')
  pathelement(:location => '${emma.dir}/emma_ant.jar')
end
# <patternset id="java.src.pattern">
#   <include name="**/*.java"/>
#   <exclude unless="bsf.present" name="org/jruby/javasupport/bsf/**/*.java"/>
#   <exclude unless="jdk1.4+" name="**/XmlAstMarshal.java"/>
#   <exclude unless="jdk1.4+" name="**/AstPersistenceDelegates.java"/>
#   <exclude unless="sun-misc-signal" name="**/SunSignalFacade.java"/>
# </patternset>
patternset(:id => 'java.src.pattern') do
  include(:name => '**/*.java')
  exclude(:unless => 'bsf.present', :name => 'org/jruby/javasupport/bsf/**/*.java')
  exclude(:unless => 'jdk1.4+', :name => '**/XmlAstMarshal.java')
  exclude(:unless => 'jdk1.4+', :name => '**/AstPersistenceDelegates.java')
  exclude(:unless => 'sun-misc-signal', :name => '**/SunSignalFacade.java')
end
# <patternset id="ruby.src.pattern">
#  <include name="**/*.rb"/>
# </patternset>
patternset(:id => 'ruby.src.patter') do
  include(:name => '**/*.rb')
end
# <patternset id="other.src.pattern">
#  <include name="**/*.properties"/>
# </patternset>
patternset(:id => 'other.src.pattern') do
  include( :name => '**/*.rb')
end
# <taskdef name="retro"
# classname="net.sourceforge.retroweaver.ant.RetroWeaverTask"
# classpathref="build.classpath"/>
taskdef(:name => 'retro',
        :classname => 'net.sourceforge.retroweaver.ant.RetroWeaverTask',
        :classpathref => 'build.classpath')

#<target name="init">
#   <xmlproperty file="build-config.xml" keepRoot="false" collapseAttributes="true"/>
#   <tstamp><format property="build.date" pattern="yyyy-MM-dd"/></tstamp>
#   <property environment="env"/>
#   <property name="version.ruby" value="${version.ruby.major}.${version.ruby.minor}"/>
#   <!-- if ruby.home is not set, use env var -->
#   <condition property="ruby.home" value="${env.RUBY_HOME}">
#     <not><isset property="ruby.home"/></not>
#   </condition>
#   <property name="rdoc.archive" value="docs/rdocs.tar.gz"/>
#   <uptodate property="docsNotNeeded" srcfile="${rdoc.archive}" targetfile="${basedir}/share/ri/1.8/system/created.rid"/>
# </target>
target :init do
  xmlproperty(:file => 'build-config.xml', :keepRoot => 'false', :collapseAttributes => true) if File.exists?('build-config.xml')
  tstamp do |t|
    t.format(:property => 'build.date', :pattern => 'yyyy-MM-dd')
  end
  property(:environment => "env")
  property(:name => 'version.ruby', :value => '${version.ruby.major}.${version.ruby.minor}')
  condition(:property => 'ruby.home', :value => '${env.RUBY_HOME}') do
    _not do |n|
      n.isset(:property => 'ruby.home')
    end
  end
  property(:name => 'rdoc.archive', :value => 'docs/rdocs.tar.gz')
  uptodate(:property => 'docsNotNeeded', :srcfile => '${rdoc.archive}', :targetfile => @base_dir + '/share/ri/1.8/system/created.rid')
end

#    <target name="extract-rdocs" depends="init" unless="docsNotNeeded">
#        <untar src="${rdoc.archive}" dest="${basedir}" compression="gzip"/>
#        <touch file="${basedir}/share/ri/1.8/system/created.rid"/>
#    </target>

target :extract_rdocs, :depends => :init do 
  untar(:src => '${rdoc.archive}', :dest => @base_dir, :compression => 'gzip') unless @docsNotNeeded
end

#    <!-- Creates the directories needed for building -->
#    <target name="prepare" depends="extract-rdocs">
#      <mkdir dir="${build.dir}"/>
#      <mkdir dir="${classes.dir}"/>
#      <mkdir dir="${jruby.classes.dir}"/>
#      <mkdir dir="${test.classes.dir}"/>
#      <mkdir dir="${test.results.dir}"/>
#      <mkdir dir="${html.test.results.dir}"/>
#      <mkdir dir="${docs.dir}"/>
#      <mkdir dir="${api.docs.dir}"/>
#    </target>
target :prepare  do
  mkdir :dir => @build_dir
  mkdir :dir => @classes_dir
  mkdir :dir => @jruby_classes_dir
  mkdir :dir => @test_classes_dir
  mkdir :dir => @test_results_dir
  mkdir :dir => @html_test_results_dir
  mkdir :dir => @docs_dir
  mkdir :dir => @api_docs_dir
end

#    <!-- Checks if specific libs and versions are avaiable -->
#    <target name="check-for-optional-java4-packages"
#            depends="init">
#      <available property="jdk1.4+" classname="java.lang.CharSequence"/>
#      <available property="jdk1.5+" classname="java.lang.StringBuilder"/>
#      <available property="bsf.present" classname="org.apache.bsf.BSFManager"
#                 classpathref="build.classpath"/>
#      <available property="junit.present" classname="junit.framework.TestCase"
#                 classpathref="build.classpath"/>
#      <available property="cglib.present"
#                 classname="net.sf.cglib.reflect.FastClass"
#                 classpathref="build.classpath"/>
#    </target>
#
target :check_for_optional_java4_packages, :depends => :init do
  available(:property => 'jdk1.4+', :classname => 'java.lang.CharSequence')
  available(:property => 'jdk1.5+', :classname => 'java.lang.StringBuilder')
  available(:property => 'bsf.present', :classname => 'org.apache.bsf.BSFManager', :classpathref => 'build.classpath')
  available(:property => 'junit.present', :classname => 'junit.framework.TestCase', :classpathref => 'build.classpath')
  available(:property => 'cglib.present', :classname => 'net.sf.cglib.reflect.FastClass', :classpathref => 'build.classpath')
end

#    <!-- Checks if specific libs and versions are avaiable -->
#    <target name="check-for-optional-packages" if="jdk1.5+"
#            depends="check-for-optional-java4-packages">
#      <available property="sun-misc-signal"
#                 classname="sun.misc.Signal"/>
#    </target>

target :check_for_optional_packages, :depends => :check_for_optional_java4_packages do # TODO if jdk1.5+
  available(:property => 'sun-misc-signal', :classname => 'sun.misc.Signal')
end

#<!-- Builds the Ant tasks that we need later on in the build -->
# <target name="compile-tasks" depends="prepare">
#   <copy todir="${jruby.classes.dir}">
#       <fileset dir="${src.dir}">
#           <include name="**/*.rb"/>
#       </fileset>
#   </copy>
#   <copy todir="${jruby.classes.dir}/builtin">
#       <fileset dir="${lib.dir}/ruby/site_ruby/1.8/builtin">
#           <include name="**/*.rb"/>
#       </fileset>
#   </copy>
#
#   <tstamp>
#       <format property="build.date" pattern="yyyy-MM-dd"/>
#   </tstamp>
#
#   <copy todir="${jruby.classes.dir}" overwrite="true">
#       <fileset dir="${src.dir}">
#           <include name="**/*.properties"/>
#       </fileset>
#       <filterset>
#           <filter token="os.arch" value="${os.arch}"/>
#           <filter token="java.specification.version" value="${java.specification.version}"/>
#           <filter token="javac.version" value="${javac.version}"/>
#           <filter token="build.date" value="${build.date}"/>
#       </filterset>
#   </copy>
# </target>
target :compile_tasks, :depends => :prepare do
  copy(:toDir => @jruby_classes_dir) do
    fileset(:dir => @src_dir) do
      include :name => '**/*.rb'
    end
  end
  copy(:toDir => @jruby_classes_dir + '/builtin') do
    fileset(:dir => @lib_dir + '/ruby/site_ruby/1.8/builtin') do
      include :name => '**/*.rb'
    end
  end
  tstamp do |t|
    t.format(:property => 'build.date', :pattern => 'yyyy-MM-dd')
  end
  copy(:todir => @jruby_classes_dir, :overwrite => 'true') do
    fileset(:dir => @src_dir) do
      include(:name => '**/*.properties')
    end
    filterset do |t|
      filter :token => 'os.arch', :value => '${os.arch}'
      filter :token => 'java.specification.version', :value => '${java.specification.version}'
      filter :token => 'javac.version', :value => '${javac.version}'
      filter :token => 'build.date', :value => '${build.date}'
    end
  end
end


# Execute

build :prepare

                         
