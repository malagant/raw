RESOURCE_DIR = File.join(FileUtils::pwd, '../spec/resources')
ANT_HOME = ENV['ANT_HOME'] || File.join(RESOURCE_DIR, 'apache-ant-1.7.1')

RAW::RAWClassLoader.load_ant_libs ANT_HOME


init_project :basedir => '/Users/mjohann/projects/jruby_raw',
             :name => 'JRuby',
             :default => 'jar',
             :anthome => ANT_HOME

property(:name => 'base.dir', :location => project.get_property('basedir'))

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

build_properties

# <!-- Gem file names -->
property :name => "rspec.gem", :value => "rspec-1.2.6.gem"
property :name => "rake.gem", :value => "rake-0.8.7.gem"

@resource_dir = RESOURCE_DIR
@ant_home = ANT_HOME
@jruby_src = @resource_dir + '/jruby-1.1.6'
@build_lib_dir = @jruby_src + "/" + property_value('build.lib.dir')


# <path id="build.classpath">
#  <fileset dir="${build.lib.dir}" includes="*.jar"/>
# </path>
path( :id => 'build.classpath') do |p|
  p.fileset( :dir => @build_lib_dir, :includes => '*.jar')
end
# <property name="emma.dir" value="${build.lib.dir}" />
property( :name => 'emma.dir', :value => @build_lib_dir)
# <path id="emma.classpath">
#  <pathelement location="${emma.dir}/emma.jar" />
#  <pathelement location="${emma.dir}/emma_ant.jar" />
# </path>
path(:id => 'emma.classpath') do
  pathelement(:location => @emma_dir + '/emma.jar')
  pathelement(:location => @emma_dir + '/emma_ant.jar')
end
# <patternset id="java.src.pattern">
#   <include name="**/*.java"/>
#   <exclude unless="bsf.present" name="org/jruby/javasupport/bsf/**/*.java"/>
#   <exclude unless="sun-misc-signal" name="**/SunSignalFacade.java"/>
# </patternset>
patternset(:id => 'java.src.pattern') do
  include(:name => '**/*.java')
  exclude(:unless => 'bsf.present', :name => 'org/jruby/javasupport/bsf/**/*.java')
  exclude(:unless => 'sun-misc-signal', :name => '**/SunSignalFacade.java')
end
# <patternset id="ruby.src.pattern">
#  <include name="**/*.rb"/>
# </patternset>
patternset(:id => 'ruby.src.pattern') do
  include(:name => '**/*.rb')
end
# <patternset id="other.src.pattern">
#  <include name="**/*.properties"/>
# </patternset>
patternset(:id => 'other.src.pattern') do
  include( :name => '**/*.properties')
end

#<import file="netbeans-ant.xml" optional="true"/>
# TODO _import :file => "netbeans-ant.xml", :optional => true

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
  xmlproperty(:file => 'build-config.xml', :keepRoot => 'false', :collapseAttributes => true) if File.exists?(@base_dir +'/build-config.xml')
  tstamp do |t|
    t.format(:property => 'build.date', :pattern => 'yyyy-MM-dd')
  end
  property(:environment => "env")
  property(:name => 'version.ruby', :value => "#{property_value("version.ruby.major")}.#{property_value("version.ruby.minor")}")
  condition(:property => 'ruby.home', :value => "#{@env_RUBY_HOME}") do
    _not do |n|
      n.isset(:property => 'ruby.home')
    end
  end
  property(:name => 'rdoc.archive', :value => 'docs/rdocs.tar.gz')
  uptodate(:property => 'docsNotNeeded', :srcfile => "#{@rdoc_archive}", :targetfile => basedir + '/share/ri/1.8/system/created.rid')
end

#    <target name="extract-rdocs" depends="init" unless="docsNotNeeded">
#        <untar src="${rdoc.archive}" dest="${basedir}" compression="gzip"/>
#        <touch file="${basedir}/share/ri/1.8/system/created.rid"/>
#    </target>
target :extract_rdocs, :depends => :init, :unless => "docsNotNeeded" do
  build :init
  unless @docsNotNeeded
    logger.debug "*** '#{@rdoc_archive}' basedir = #{basedir}"
    untar(:src => "#{@rdoc_archive}", :dest => basedir, :compression => 'gzip')
    touch(:file => "#{basedir}/share/ri/1.8/system/created.rid")
  end
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
  build :extract_rdocs
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
target :check_for_optional_java4_packages do
  build :init
  available(:property => 'jdk1_5_plus', :classname => 'java.lang.StringBuilder')
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

target :check_for_optional_packages do # TODO if jdk1.5+
  build :check_for_optional_java4_packages
  available(:property => 'sun_misc_signal', :classname => 'sun.misc.Signal')
end

#<target name="prepare-resources" depends="prepare">
#  <copy todir="${jruby.classes.dir}">
#      <fileset dir="${src.dir}">
#          <include name="**/*.rb"/>
#      </fileset>
#  </copy>
#  <copy todir="${jruby.classes.dir}/builtin">
#      <fileset dir="${lib.dir}/ruby/site_ruby/1.8/builtin">
#          <include name="**/*.rb"/>
#      </fileset>
#  </copy>
#
#  <tstamp>
#      <format property="build.date" pattern="yyyy-MM-dd"/>
#  </tstamp>
#
#  <copy todir="${jruby.classes.dir}" overwrite="true">
#      <fileset dir="${src.dir}">
#          <include name="**/*.properties"/>
#      </fileset>
#      <filterset>
#          <filter token="os.arch" value="${os.arch}"/>
#          <filter token="java.specification.version" value="${java.specification.version}"/>
#          <filter token="javac.version" value="${javac.version}"/>
#          <filter token="build.date" value="${build.date}"/>
#      </filterset>
#  </copy>
#</target>
target :prepare_resources do
  build :prepare
  copy :todir => @jruby_classes_dir do
    fileset :dir => @src_dir do
      include :name => "**/*.rb"
    end
  end
  copy :todir => "#{@jruby_classes_dir}/builtin" do
    fileset :dir => "#{@lib_dir}/ruby/site_ruby/1.8/builtin" do
      include :name => "**/*.rb"
    end
  end

  tstamp do |t|
    t.format :property => "build.date", :pattern => "yyyy-MM-dd"
  end

  copy :todir => @jruby_classes_dir, :overwrite => true do
    fileset :dir => @src_dir do
      include :name => "**/*.properties"
    end
    filterset do
      filter :token => "os.arch", :value => @os_arch
      filter :token => "java.specification.version", :value => @java_specification_version
      filter :token => "javac.version", :value => @javac_version
      filter :token => "build.date", :value => @build_date
    end
  end
end
#<target name="compile-annotation-binder">
#  <mkdir dir="${basedir}/src_gen"/>
#
#  <javac destdir="${jruby.classes.dir}" debug="true" srcdir="${src.dir}" sourcepath="" classpathref="build.classpath" source="${javac.version}" target="${javac.version}" deprecation="true" encoding="UTF-8">
#      <include name="org/jruby/anno/FrameField.java"/>
#      <include name="org/jruby/anno/AnnotationBinder.java"/>
#      <include name="org/jruby/anno/JRubyMethod.java"/>
#      <include name="org/jruby/anno/FrameField.java"/>
#      <include name="org/jruby/CompatVersion.java"/>
#      <include name="org/jruby/runtime/Visibility.java"/>
#      <include name="org/jruby/util/CodegenUtils.java"/>
#  </javac>
#</target>
target :compile_annotation_binder do
  mkdir :dir => "#{basedir}/src_gen"

  javac :destdir => @jruby_classes_dir, :debug => true,
        :srcdir => @src_dir, :sourcepath => "", :classpathref => "build.classpath",
        :source => @javac_version, :target => @javac_version, :deprecation => true, :encoding => "UTF-8" do
    include :name => "org/jruby/anno/FrameField.java"
    include :name => "org/jruby/anno/AnnotationBinder.java"
    include :name => "org/jruby/anno/JRubyMethod.java"
    include :name => "org/jruby/anno/FrameField.java"
    include :name => "org/jruby/CompatVersion.java"
    include :name => "org/jruby/runtime/Visibility.java"
    include :name => "org/jruby/util/CodegenUtils.java"
  end
end
#<target name="compile-annotation-binder">
#  <mkdir dir="${basedir}/src_gen"/>
#
#  <javac destdir="${jruby.classes.dir}" debug="true" srcdir="${src.dir}" sourcepath="" classpathref="build.classpath"
#       source="${javac.version}" target="${javac.version}" deprecation="true" encoding="UTF-8">
#      <include name="org/jruby/anno/FrameField.java"/>
#      <include name="org/jruby/anno/AnnotationBinder.java"/>
#      <include name="org/jruby/anno/JRubyMethod.java"/>
#      <include name="org/jruby/anno/FrameField.java"/>
#      <include name="org/jruby/CompatVersion.java"/>
#      <include name="org/jruby/runtime/Visibility.java"/>
#      <include name="org/jruby/util/CodegenUtils.java"/>
#  </javac>
#</target>
#
target :compile_annotation_binder do
  mkdir :dir => @base_dir + '/src_gen'
  javac(:destdir => @jruby_classes_dir,
        :debug => true,
        :srcdir => @src_dir,
        :sourcepath => '',
        :classpath => 'build.classpath',
        :source => @javac_version,
        :target => @javac_version,
        :deprecation => true,
        :encoding => 'UTF-8') do
    include(:name => 'org/jruby/anno/FrameField.java')
    include(:name => 'org/jruby/anno/AnnotationBinder.java')
    include(:name => 'org/jruby/anno/JRubyMethod.java')
    include(:name => 'org/jruby/CompatVersion.java')
    include(:name => 'org/jruby/runtime/Visibility.java')
    include(:name => 'org/jruby/util/CodegenUtils.java')
  end
end
#<target name="compile-jruby" depends="compile-tasks, compile-annotation-binder, check-for-optional-packages">
#  <!-- Generate binding logic ahead of time -->
#  <apt factory="org.jruby.anno.AnnotationBinder" destdir="${jruby.classes.dir}" debug="true" source="${javac.version}"
#     target="${javac.version}" deprecation="true" encoding="UTF-8">
#    <classpath refid="build.classpath"/>
#    <classpath path="${jruby.classes.dir}"/>
#    <src path="${src.dir}"/>
#    <patternset refid="java.src.pattern"/>
#    <compilerarg line="-XDignore.symbol.file=true"/>
#    <compilerarg line="-J-Xmx512M"/>
#  </apt>
#</target>
target :compile_jruby do
  build :prepare_resources
  build :compile_annotation_binder
  build :check_for_optional_packages

  apt(:factory => 'org.jruby.anno.AnnotationBinder',
      :destdir => @jruby_classes_dir,
      :debug => true,
      :source => @javac_version,
      :target => @javac_version,
      :deprecation => true,
      :encoding => 'UTF-8') do
    classpath(:refid => 'build.classpath')
    classpath(:path => @jruby_classes_dir)
    src(:path => @src_dir)
    patternset(:refid => 'java.src.pattern')
    compilerarg(:line => '-XDignore.symbol.file=true')
    compilerarg(:line => '-J-Xmx512M')
  end
end

#<target name="compile" depends="compile-jruby"
#        description="Compile the source files for the project.">
#</target>
target :compile do
  # Compile the source files for the project.
  build :compile_jruby
end
#<target name="generate-method-classes" depends="compile">
#  <available file="src_gen/annotated_classes.txt" property="annotations.changed"/>
#  <antcall target="_gmc_internal_"/>
#</target>
target :generate_method_classes do
  build :compile
  available(:file => 'src_gen/annotated_classes.txt', :property => 'annotations.changed')
  build :_gmc_internal_ if @annotations_changed # TODO was antcall
end
#<target name="_gmc_internal_" if="annotations.changed">
#  <echo message="Generating invokers..."/>
#  <java classname="org.jruby.anno.InvokerGenerator" fork="true" failonerror="true">
#    <classpath refid="build.classpath"/>
#    <classpath path="${jruby.classes.dir}"/>
#    <!-- uncomment this line when building on a JVM with invokedynamic
#    <jvmarg line="-XX:+InvokeDynamic"/>
#    -->
#    <arg value="src_gen/annotated_classes.txt"/>
#    <arg value="${jruby.classes.dir}"/>
#  </java>
#
#  <echo message="Compiling populators..."/>
#  <javac destdir="${jruby.classes.dir}" debug="true" source="${javac.version}" target="${javac.version}" deprecation="true" encoding="UTF-8">
#     <classpath refid="build.classpath"/>
#     <classpath path="${jruby.classes.dir}"/>
#     <src path="src_gen"/>
#     <patternset refid="java.src.pattern"/>
#  </javac>
#
#  <delete file="src_gen/annotated_classes.txt"/>
#</target>
target :_gmc_internal_, :if => 'annotations.changed' do
  echo :message => 'Generating invokers...'

  _java(:classname => 'org.jruby.anno.InvokerGenerator',
        :fork => true,
        :failonerror => true) do
    classpath :refid => 'build.classpath'
    classpath :path => @jruby_classes_dir
    # uncomment this line when building on a JVM with invokedynamic
    # jvmarg :line => '-XX:+InvokeDynamic'
    arg :value => 'src_gen/annotated_classes.txt'
    arg :value => @jruby_classes_dir
  end

  echo :message => 'Compiling populators...'

  _java(:destdir => @jruby_classes_dir,
        :debug => true,
        :source => @javac_version,
        :target => @javac_version,
        :deprecation => true,
        :encoding => 'UTF-8') do
    classpath :refid => 'build.classpath'
    classpath :path => @jruby_classes_dir
    src :path => 'src_gen'
    patternset :refid => 'java.src.pattern'
  end
  delete :file => 'src_gen/annotated_classes.txt'
end

#<target name="generate-unsafe" depends="compile">
#    <available file="${jruby.classes.dir}/org/jruby/util/unsafe/GeneratedUnsafe.class" property="unsafe.not.needed"/>
#    <antcall target="_gu_internal_"/>
#</target>
target :generate_unsafe do
  build :compile
  available :file => @jruby_classes_dir + '/org/jruby/util/unsafe/GeneratedUnsafe.class', :property => 'unsafe.not.needed'
  build :_gu_internal_
end
#<target name="_gu_internal_" unless="unsafe.not.needed">
#  <echo message="Generating Unsafe impl..."/>
#  <java classname="org.jruby.util.unsafe.UnsafeGenerator" fork="true" failonerror="true">
#      <classpath refid="build.classpath"/>
#      <classpath path="${jruby.classes.dir}"/>
#      <!-- uncomment this line when building on a JVM with invokedynamic
#      <jvmarg line="-XX:+InvokeDynamic"/>
#      -->
#      <arg value="org.jruby.util.unsafe"/>
#      <arg value="${jruby.classes.dir}/org/jruby/util/unsafe"/>
#  </java>
#</target>
target :_gu_internal_, :unless => [ 'unsafe.not.needed'] do
  echo :message => 'Generating unsafe impl...'
  _java(:classname => 'org.jruby.util.unsafe.UnsafeGenerator', :fork => true, :failonerror => true) do |j|
    j.classpath :refid => 'build.classpath'
    j.classpath :path => @jruby_classes_dir
    # uncomment this line when building on a JVM with invokedynamic
    # jvmarg :line => '-XX:+InvokeDynamic'
    j.arg :value => 'org.jruby.util.unsafe'
    j.arg :value => @jruby_classes_dir + '/org/jruby/util/unsafe'
  end
end

#<target name="_update_scm_revision_">
#    <java classname="org.jruby.Main" resultproperty="snapshot.result" errorproperty="snapshot.error" failonerror="false">
#      <classpath refid="build.classpath"/>
#      <classpath path="${jruby.classes.dir}"/>
#      <sysproperty key="jruby.home" value="${jruby.home}"/>
#      <arg value="tool/snapshot.rb"/>
#      <arg value="${jruby.classes.dir}/org/jruby/jruby.properties"/>
#    </java>
#</target>
#
target :_update_scm_revision_ do
  _java :classname => "org.jruby.Main", :resultproperty => "snapshot.result",
        :errorproperty => "snapshot.error", :failonerror => false do
    classpath :refid => "build.classpath"
    classpath :path => @jruby_classes_dir
    sysproperty :key => "jruby.home", :value => @jruby_home
    arg :value => "tool/snapshot.rb"
    arg :value => "#{@jruby_classes_dir}/org/jruby/jruby.properties"
  end
end


#<target name="jar-jruby" depends="generate-method-classes, generate-unsafe" unless="jar-up-to-date">
#    <antcall target="_update_scm_revision_"/>
#
#    <jar destfile="${lib.dir}/jruby.jar" compress="true" index="true">
#      <fileset dir="${jruby.classes.dir}"/>
#      <zipfileset src="${build.lib.dir}/asm-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-commons-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-util-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-analysis-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-tree-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/bytelist.jar"/>
#      <zipfileset src="${build.lib.dir}/constantine.jar"/>
#      <zipfileset src="${build.lib.dir}/jvyamlb-0.2.5.jar"/>
#      <zipfileset src="${build.lib.dir}/jline-0.9.93.jar"/>
#      <zipfileset src="${build.lib.dir}/jcodings.jar"/>
#      <zipfileset src="${build.lib.dir}/joni.jar"/>
#      <zipfileset src="${build.lib.dir}/jna-posix.jar"/>
#      <zipfileset src="${build.lib.dir}/jna.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-i386-Linux.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-x86_64-Linux.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-Darwin.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-i386-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-x86_64-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-ppc-AIX.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-sparc-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-sparcv9-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/joda-time-1.5.1.jar"/>
#      <zipfileset src="${build.lib.dir}/dynalang-0.3.jar"/>
#      <zipfileset src="${build.lib.dir}/yydebug.jar"/>
#      <zipfileset src="${build.lib.dir}/nailgun-0.7.1.jar"/>
#      <manifest>
#        <attribute name="Built-By" value="${user.name}"/>
#        <attribute name="Main-Class" value="org.jruby.Main"/>
#      </manifest>
#    </jar>
#</target>
target :jar_jruby, :unless => "jar-up-to-date" do
  build :generate_method_classes
  build :generate_unsafe
  #build :_update_scm_revision_ # TODO antcall

  jar :destfile => "#{@lib_dir}/jruby.jar", :compress => true, :index => true do |j|
    j.fileset :dir => @jruby_classes_dir
    j.zipfileset :src => "#{@build_lib_dir}/asm-3.1.jar"
    j.zipfileset :src => "#{@build_lib_dir}/asm-commons-3.1.jar"
    j.zipfileset :src => "#{@build_lib_dir}/asm-util-3.1.jar"
    j.zipfileset :src => "#{@build_lib_dir}/asm-analysis-3.1.jar"
    j.zipfileset :src => "#{@build_lib_dir}/asm-tree-3.1.jar"
    j.zipfileset :src => "#{@build_lib_dir}/bytelist.jar"
    j.zipfileset :src => "#{@build_lib_dir}/constantine.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jvyamlb-0.2.5.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jline-0.9.93.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jcodings.jar"
    j.zipfileset :src => "#{@build_lib_dir}/joni.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jna-posix.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jna.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-i386-Linux.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-x86_64-Linux.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-Darwin.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-i386-SunOS.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-x86_64-SunOS.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-ppc-AIX.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-sparc-SunOS.jar"
    j.zipfileset :src => "#{@build_lib_dir}/jffi-sparcv9-SunOS.jar"
    j.zipfileset :src => "#{@build_lib_dir}/joda-time-1.5.1.jar"
    j.zipfileset :src => "#{@build_lib_dir}/dynalang-0.3.jar"
    j.zipfileset :src => "#{@build_lib_dir}/yydebug.jar"
    j.zipfileset :src => "#{@build_lib_dir}/nailgun-0.7.1.jar"
    manifest do
      attribute :name => "Built-By", :value => @user_name
      attribute :name => "Main-Class", :value => "org.jruby.Main"
    end
  end
end

#<target name="jar" depends="init" description="Create the jruby.jar file">
#  <antcall target="jar-jruby" inheritall="true"/>
#</target>
target :jar, :depends => :init do
  build :compile
  build :jar_jruby  # TODO , :inheritall => true
end
#<target name="jar-dist" depends="init" description="Create the jruby.jar file for distribution. This version uses JarJar Links to rewrite some packages.">
#  <antcall target="jar-jruby-dist" inheritall="true"/>
#</target>
target :jar_dist, :depends => :init do
  build :init
  build :jar_jruby_dist # TODO :inheritall => true
end

#<target name="jar-jruby-dist" depends="generate-method-classes, generate-unsafe" unless="jar-up-to-date">
#    <antcall target="_update_scm_revision_"/>
#
#    <taskdef name="jarjar" classname="com.tonicsystems.jarjar.JarJarTask" classpath="${build.lib.dir}/jarjar-1.0rc8.jar"/>
#    <jarjar destfile="${lib.dir}/jruby.jar" compress="true">
#      <fileset dir="${jruby.classes.dir}"/>
#      <zipfileset src="${build.lib.dir}/asm-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-commons-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-util-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-analysis-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/asm-tree-3.1.jar"/>
#      <zipfileset src="${build.lib.dir}/constantine.jar"/>
#      <zipfileset src="${build.lib.dir}/bytelist.jar"/>
#      <zipfileset src="${build.lib.dir}/jvyamlb-0.2.5.jar"/>
#      <zipfileset src="${build.lib.dir}/jline-0.9.93.jar"/>
#      <zipfileset src="${build.lib.dir}/jcodings.jar"/>
#      <zipfileset src="${build.lib.dir}/joni.jar"/>
#      <zipfileset src="${build.lib.dir}/jna-posix.jar"/>
#      <zipfileset src="${build.lib.dir}/jna.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-i386-Linux.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-amd64-Linux.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-Darwin.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-x86-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-amd64-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-ppc-AIX.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-sparc-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/jffi-sparcv9-SunOS.jar"/>
#      <zipfileset src="${build.lib.dir}/joda-time-1.5.1.jar"/>
#      <zipfileset src="${build.lib.dir}/dynalang-0.3.jar"/>
#      <zipfileset src="${build.lib.dir}/yydebug.jar"/>
#      <zipfileset src="${build.lib.dir}/nailgun-0.7.1.jar"/>
#      <manifest>
#        <attribute name="Built-By" value="${user.name}"/>
#        <attribute name="Main-Class" value="org.jruby.Main"/>
#      </manifest>
#      <rule pattern="org.objectweb.asm.**" result="jruby.objectweb.asm.@1"/>
#    </jarjar>
#    <antcall target="_osgify-jar_">
#      <param name="bndfile" value="jruby.bnd" />
#      <param name="jar.wrap" value="${lib.dir}/jruby.jar" />
#    </antcall>
#</target>
target :jar_jruby_dist, :unless => "jar-up-to-date" do
  build :generate_method_classes
  build :generate_unsafe
  # TODO  <antcall target="_update_scm_revision_"/>

  taskdef :name => "jarjar", :classname => "com.tonicsystems.jarjar.JarJarTask",
          :classpath => "#{@build_lib_dir}/jarjar-1.0rc8.jar"
  jarjar :destfile => "#{@lib_dir}/jruby.jar", :compress => true do
    fileset :dir => "#{@jruby_classes_dir}"
    zipfileset :src => "#{@build_lib_dir}/asm-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-commons-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-util-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-analysis-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-tree-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/constantine.jar"
    zipfileset :src => "#{@build_lib_dir}/bytelist.jar"
    zipfileset :src => "#{@build_lib_dir}/jvyamlb-0.2.5.jar"
    zipfileset :src => "#{@build_lib_dir}/jline-0.9.93.jar"
    zipfileset :src => "#{@build_lib_dir}/jcodings.jar"
    zipfileset :src => "#{@build_lib_dir}/joni.jar"
    zipfileset :src => "#{@build_lib_dir}/jna-posix.jar"
    zipfileset :src => "#{@build_lib_dir}/jna.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-i386-Linux.jar"
    # zipfileset :src => "#{@build_lib_dir}/jffi-amd64-Linux.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-Darwin.jar"
    # zipfileset :src => "#{@build_lib_dir}/jffi-x86-SunOS.jar"
    # zipfileset :src => "#{@build_lib_dir}/jffi-amd64-SunOS.jar"
    # zipfileset :src => "#{@build_lib_dir}/jffi-ppc-AIX.jar"
    # zipfileset :src => "#{@build_lib_dir}/jffi-sparc-SunOS.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-sparcv9-SunOS.jar"
    zipfileset :src => "#{@build_lib_dir}/joda-time-1.5.1.jar"
    zipfileset :src => "#{@build_lib_dir}/dynalang-0.3.jar"
    zipfileset :src => "#{@build_lib_dir}/yydebug.jar"
    zipfileset :src => "#{@build_lib_dir}/nailgun-0.7.1.jar"
    manifest do
      attribute :name => "Built-By", :value => @user_name
      attribute :name => "Main-Class", :value => "org.jruby.Main"
    end
    rule :pattern => "org.objectweb.asm.**", :result => "jruby.objectweb.asm.@1"
  end
  # TODO antcall enabling blocks
  #antcall :target => :_osgify_jar_ do
  #  param :name => "bndfile", :value => "jruby.bnd"
  #  param :name => "jar_wrap", :value => "@lib_dir/jruby.jar"
  #end
end
#<!-- Use Bnd to wrap the JAR generated by jarjar in above task -->
#<target name="_osgify-jar_">
#  <filter token="JRUBY_VERSION" value="${version.jruby}"/>
#  <copy file="${basedir}/jruby.bnd.template" tofile="${build.dir}/${bndfile}" filtering="true"/>
#  <taskdef resource="aQute/bnd/ant/taskdef.properties"
#    classpath="${build.lib.dir}/bnd-0.0.249.jar"/>
#  <bndwrap definitions="${build.dir}" output="${dest.lib.dir}">
#    <fileset file="${jar.wrap}" />
#  </bndwrap>
#  <move file="${jar.wrap}$" tofile="${jar.wrap}"
#    overwrite="true" />
#</target>

# <!-- Use Bnd to wrap the JAR generated by jarjar in above task -->
target :_osgify_jar_ do |bndfile, jar_wrap|
  filter :token => "JRUBY_VERSION", :value => @version_jruby
  copy :file => "#{basedir}/jruby.bnd.template", :tofile => "#{@build_dir}/#{bndfile}", :filtering => true
  taskdef :resource => "aQute/bnd/ant/taskdef.properties",
          :classpath => "#{@build_lib_dir}/bnd-0.0.249.jar"
  bndwrap :definitions => @build_dir, :output => @dest_lib_dir do
    fileset :file => jar_wrap
  end
  move :file => @jar_wrap, :tofile => @jar_wrap,
       :overwrite => true
end

#<target name="create-apidocs" depends="prepare"
#        description="Creates the Java API docs">
#  <javadoc destdir="${api.docs.dir}" author="true" version="true" use="true"
#           windowtitle="JRuby API" source="${javac.version}" useexternalfile="true"
#           maxmemory="128m">
#    <fileset dir="${src.dir}">
#      <include name="**/*.java"/>
#    </fileset>
#    <fileset dir="${test.dir}">
#  <include name="**/*.java"/>
#    </fileset>
#    <doctitle><![CDATA[<h1>JRuby</h1>]]></doctitle>
#    <bottom><![CDATA[<i>Copyright &#169; 2002-2007 JRuby Team. All Rights Reserved.</i>]]></bottom>
#  </javadoc>
#</target>
# Creates the Java API docs
target :create_apidocs do
  build :prepare
  javadoc :destdir => @api_docs_dir, :author => true, :version => true, :use => true,
          :windowtitle => "JRuby API", :source => @javac_version, :useexternalfile => true,
          :maxmemory => "128m" do
    fileset :dir => @src_dir do
      include :name => "**/*.java"
    end
    fileset :dir => @test_dir do
      include :name => "**/*.java"
    end
    doctitle "<![CDATA[<h1>JRuby</h1>]]>"
    bottom "<![CDATA[<i>Copyright &#169; 2002-2007 JRuby Team. All Rights Reserved.</i>]]>"
  end
end

#<patternset id="dist.bindir.files">
#  <include name="bin/*jruby*"/>
#  <include name="bin/*gem*"/>
#  <include name="bin/*ri*"/>
#  <include name="bin/*rdoc*"/>
#  <include name="bin/*jirb*"/>
#  <include name="bin/generate_yaml_index.rb"/>
#  <include name="bin/testrb"/>
#  <include name="bin/ast*"/>
#  <include name="bin/spec.bat"/>
#  <include name="bin/rake.bat"/>
#</patternset>
patternset :id => "dist.bindir.files" do
  include :name => "bin/*jruby*"
  include :name => "bin/*gem*"
  include :name => "bin/*ri*"
  include :name => "bin/*rdoc*"
  include :name => "bin/*jirb*"
  include :name => "bin/generate_yaml_index.rb"
  include :name => "bin/testrb"
  include :name => "bin/ast*"
  include :name => "bin/spec.bat"
  include :name => "bin/rake.bat"
end

#<patternset id="dist.lib.files">
#  <include name="lib/ruby/1.8/**"/>
#  <include name="lib/ruby/site_ruby/1.8/**"/>
#  <include name="lib/ruby/1.9/**"/>
#  <include name="lib/ruby/site_ruby/1.9/**"/>
#  <include name="lib/ruby/gems/1.8/specifications/sources-0.0.1.gemspec"/>
#  <include name="lib/ruby/gems/1.8/gems/sources-0.0.1/**"/>
#</patternset>
patternset :id => "dist.lib.files" do
  include :name => "lib/ruby/1.8/**"
  include :name => "lib/ruby/site_ruby/1.8/**"
  include :name => "lib/ruby/1.9/**"
  include :name => "lib/ruby/site_ruby/1.9/**"
  include :name => "lib/ruby/gems/1.8/specifications/sources-0.0.1.gemspec"
  include :name => "lib/ruby/gems/1.8/gems/sources-0.0.1/**"
end

#<patternset id="dist.files">
#  <include name="lib/*"/>
#  <include name="samples/**"/>
#  <include name="docs/**"/>
#  <include name="COPYING*"/>
#  <include name="README"/>
#  <exclude name="lib/ruby/**"/>
#</patternset>
patternset :id => "dist.files" do
  include :name => "lib/*"
  include :name => "samples/**"
  include :name => "docs/**"
  include :name => "COPYING*"
  include :name => "README"
  exclude :name => "lib/ruby/**"
end

#<patternset id="dist.bin.files">
#  <patternset refid="dist.files"/>
#  <exclude name="lib/emma.jar"/>
#  <exclude name="lib/emma_ant.jar"/>
#  <exclude name="lib/junit.jar"/>
#  <exclude name="lib/jarjar-1.0rc8.jar"/>
#  <exclude name="docs/rdocs.tar.gz"/>
#  <exclude name="bench/**"/>
#  <include name="share/**"/>
#  <include name="tool/nailgun/**"/>
#</patternset>
patternset :id => "dist.bin.files" do
  patternset :refid => "dist.files"
  exclude :name => "lib/emma.jar"
  exclude :name => "lib/emma_ant.jar"
  exclude :name => "lib/junit.jar"
  exclude :name => "lib/jarjar-1.0rc8.jar"
  exclude :name => "docs/rdocs.tar.gz"
  exclude :name => "bench/**"
  include :name => "share/**"
  include :name => "tool/nailgun/**"
end

#<patternset id="dist.src.files">
#  <patternset refid="dist.files"/>
#  <exclude name="share/**"/>
#  <include name="bench/**"/>
#  <include name="src/**"/>
#  <include name="test/**"/>
#  <include name="spec/**"/>
#  <include name="tool/**"/>
#  <include name="build_lib/**"/>
#  <include name="Rakefile"/>
#  <include name="build.xml"/>
#  <include name="build-config.xml"/>
#  <include name="nbproject/*"/>
#  <include name=".project"/>
#  <include name=".classpath"/>
#  <include name="default.build.properties"/>
#  <include name="jruby.bnd.template"/>
#  <exclude name="lib/jruby.jar"/>
#</patternset>
patternset :id => "dist.src.files" do
  patternset :refid => "dist.files"
  exclude :name => "share/**"
  include :name => "bench/**"
  include :name => "src/**"
  include :name => "test/**"
  include :name => "spec/**"
  include :name => "tool/**"
  include :name => "build_lib/**"
  include :name => "Rakefile"
  include :name => "build.xml"
  include :name => "build-config.xml"
  include :name => "nbproject/*"
  include :name => ".project"
  include :name => ".classpath"
  include :name => "default.build.properties"
  include :name => "jruby.bnd.template"
  exclude :name => "lib/jruby.jar"
end


#<target name="jar-complete" depends="generate-method-classes, generate-unsafe" description="Create the 'complete' JRuby jar. Pass 'mainclass' and 'filename' to adjust.">
#  <property name="mainclass" value="org.jruby.Main"/>
#  <property name="filename" value="jruby-complete.jar"/>
#  <taskdef name="jarjar" classname="com.tonicsystems.jarjar.JarJarTask" classpath="${build.lib.dir}/jarjar-1.0rc8.jar"/>
#  <property name="jar-complete-home" value="${build.dir}/jar-complete/META-INF/jruby.home"/>
#  <mkdir dir="${jar-complete-home}"/>
#  <copy todir="${jar-complete-home}">
#    <fileset dir="${basedir}">
#      <patternset refid="dist.bindir.files"/>
#      <patternset refid="dist.lib.files"/>
#    </fileset>
#  </copy>
#  <copy todir="${build.dir}/jar-complete">
#    <fileset dir="lib/ruby/1.8" includes="**/*"/>
#  </copy>
#
#  <java classname="${mainclass}" fork="true" maxmemory="${jruby.launch.memory}" failonerror="true">
#    <classpath>
#      <pathelement location="${jruby.classes.dir}"/>
#      <pathelement location="${build.dir}/jar-complete"/>
#      <path refid="build.classpath"/>
#    </classpath>
#    <sysproperty key="jruby.home" value="${build.dir}/jar-complete/META-INF/jruby.home"/>
#    <arg value="--command"/>
#    <arg value="maybe_install_gems"/>
#    <arg value="${build.lib.dir}/${rspec.gem}"/>
#    <arg value="${build.lib.dir}/${rake.gem}"/>
#    <arg value="--no-ri"/>
#    <arg value="--no-rdoc"/>
#    <arg value="--env-shebang"/>
#  </java>
#
#  <taskdef name="jarjar" classname="com.tonicsystems.jarjar.JarJarTask" classpath="${build.lib.dir}/jarjar-1.0rc8.jar"/>
#  <jarjar destfile="${dest.lib.dir}/${filename}">
#    <fileset dir="${jruby.classes.dir}"/>
#    <fileset dir="${build.dir}/jar-complete">
#      <exclude name="META-INF/jruby.home/lib/ruby/1.8/**"/>
#      <exclude name="META-INF/jruby.home/lib/ruby/1.9/**"/>
#    </fileset>
#    <zipfileset src="${build.lib.dir}/asm-3.1.jar"/>
#    <zipfileset src="${build.lib.dir}/asm-commons-3.1.jar"/>
#    <zipfileset src="${build.lib.dir}/asm-util-3.1.jar"/>
#    <zipfileset src="${build.lib.dir}/asm-analysis-3.1.jar"/>
#    <zipfileset src="${build.lib.dir}/asm-tree-3.1.jar"/>
#    <zipfileset src="${build.lib.dir}/bytelist.jar"/>
#    <zipfileset src="${build.lib.dir}/constantine.jar"/>
#    <zipfileset src="${build.lib.dir}/jvyamlb-0.2.5.jar"/>
#    <zipfileset src="${build.lib.dir}/jline-0.9.93.jar"/>
#    <zipfileset src="${build.lib.dir}/jcodings.jar"/>
#    <zipfileset src="${build.lib.dir}/joni.jar"/>
#    <zipfileset src="${build.lib.dir}/jna-posix.jar"/>
#    <zipfileset src="${build.lib.dir}/jna.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-i386-Linux.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-amd64-Linux.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-Darwin.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-x86-SunOS.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-amd64-SunOS.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-ppc-AIX.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-sparc-SunOS.jar"/>
#    <zipfileset src="${build.lib.dir}/jffi-sparcv9-SunOS.jar"/>
#    <zipfileset src="${build.lib.dir}/joda-time-1.5.1.jar"/>
#    <zipfileset src="${build.lib.dir}/dynalang-0.3.jar"/>
#    <zipfileset src="${build.lib.dir}/yydebug.jar"/>
#    <zipfileset src="${build.lib.dir}/nailgun-0.7.1.jar"/>
#    <manifest>
#      <attribute name="Built-By" value="${user.name}"/>
#      <attribute name="Main-Class" value="${mainclass}"/>
#    </manifest>
#    <rule pattern="org.objectweb.asm.**" result="jruby.objectweb.asm.@1"/>
#  </jarjar>
#  <antcall target="_osgify-jar_">
#    <param name="bndfile" value="jruby-complete.bnd" />
#    <param name="jar.wrap" value="${dest.lib.dir}/${filename}" />
#  </antcall>
#</target>
# Create the 'complete' JRuby jar. Pass 'mainclass' and 'filename' to adjust.
target :jar_complete do
  # TODO mainclass and filename parameter  as arguments
  @mainclass ||= "org.jruby.Main"
  @filename ||= 'jruby-complete.jar'
  build :generate_method_classes
  build :generate_unsafe
  property :name => @mainclass, :value => "org.jruby.Main"
  property :name => @filename, :value => "jruby-complete.jar"

  taskdef :name => "jarjar", :classname => "com.tonicsystems.jarjar.JarJarTask",
          :classpath => "#{@build_lib_dir}/jarjar-1.0rc8.jar"
  property :name => "jar_complete_home", :value => "#{@build_dir}/jar-complete/META-INF/jruby.home"
  mkdir :dir => @jar_complete_home
  copy :todir => @jar_complete_home do
    fileset :dir => basedir do
      patternset :refid => "dist.bindir.files"
      patternset :refid => "dist.lib.files"
    end
  end
  copy :todir => "#{@build_dir}/jar-complete" do
    fileset :dir => "lib/ruby/1.8", :includes => "**/*"
  end

  _java :classname => @mainclass, :fork => true, :maxmemory => @jruby_launch_memory, :failonerror => true do
    classpath do
      pathelement :location => @jruby_classes_dir
      pathelement :location => "#{@build_dir}/jar-complete"
      path :refid => "build.classpath"
    end
    sysproperty :key => "jruby.home", :value => "#{@build_dir}/jar-complete/META-INF/jruby.home"
    arg :value => "--command"
    arg :value => "maybe_install_gems"
    arg :value => "#{@build_lib_dir}/#{@rspec_gem}"
    arg :value => "#{@build_lib_dir}/#{@rake_gem}"
    arg :value => "--no-ri"
    arg :value => "--no-rdoc"
    arg :value => "--env-shebang"
  end

  taskdef :name => "jarjar", :classname => "com.tonicsystems.jarjar.JarJarTask",
          :classpath => "#{@build_lib_dir}/jarjar-1.0rc8.jar"

  jarjar :destfile => "#{@dest_lib_dir}/#{filename}" do
    fileset :dir => @jruby_classes_dir
    fileset :dir => "#{@build_dir}/jar-complete" do
      exclude :name => "META-INF/jruby.home/lib/ruby/1.8/**"
      exclude :name => "META-INF/jruby.home/lib/ruby/1.9/**"
    end
    zipfileset :src => "#{@build_lib_dir}/asm-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-commons-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-util-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-analysis-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/asm-tree-3.1.jar"
    zipfileset :src => "#{@build_lib_dir}/bytelist.jar"
    zipfileset :src => "#{@build_lib_dir}/constantine.jar"
    zipfileset :src => "#{@build_lib_dir}/jvyamlb-0.2.5.jar"
    zipfileset :src => "#{@build_lib_dir}/jline-0.9.93.jar"
    zipfileset :src => "#{@build_lib_dir}/jcodings.jar"
    zipfileset :src => "#{@build_lib_dir}/joni.jar"
    zipfileset :src => "#{@build_lib_dir}/jna-posix.jar"
    zipfileset :src => "#{@build_lib_dir}/jna.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-i386-Linux.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-amd64-Linux.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-Darwin.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-x86-SunOS.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-amd64-SunOS.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-ppc-AIX.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-sparc-SunOS.jar"
    zipfileset :src => "#{@build_lib_dir}/jffi-sparcv9-SunOS.jar"
    zipfileset :src => "#{@build_lib_dir}/joda-time-1.5.1.jar"
    zipfileset :src => "#{@build_lib_dir}/dynalang-0.3.jar"
    zipfileset :src => "#{@build_lib_dir}/yydebug.jar"
    zipfileset :src => "#{@build_lib_dir}/nailgun-0.7.1.jar"
    manifest do
      attribute :name => "Built-By", :value => @user_name
      attribute :name => "Main-Class", :value => @mainclass
    end
    rule :pattern => "org.objectweb.asm.**", :result => "jruby.objectweb.asm.@1"
  end
  #<antcall target="_osgify-jar_">
  #  <param name="bndfile" value="jruby-complete.bnd" />
  #  <param name="jar.wrap" value="${dest.lib.dir}/${filename}" />
  #</antcall>
end



#<target name="dist-clean">
#  <delete includeEmptyDirs="true" quiet="true">
#    <fileset dir=".">
#      <include name="jruby-*.tar.gz"/>
#      <include name="jruby-*.zip"/>
#    </fileset>
#    <fileset dir="dist" includes="**/*"/>
#  </delete>
#</target>

#<target name="clean" depends="init" description="Cleans almost everything, leaves downloaded specs">
#  <delete dir="${build.dir}"/>
#  <delete dir="${dist.dir}"/>
#  <delete quiet="false">
#      <fileset dir="${lib.dir}" includes="jruby*.jar"/>
#  </delete>
#  <delete dir="${api.docs.dir}"/>
#  <delete dir="src_gen"/>
#</target>
target :clean do
  build :init
  delete :dir => @build_dir
  delete :dir => @dist_dir
  delete :quiet => false do
    fileset :dir => @lib_dir, :includes => "jruby*.jar"
  end
  delete :dir => @api_docs_dir
  delete :dir => "src_gen"
end

target :clean_all do # Cleans everything, including downloaded specs
  build :clean
  build :clear_specs
end
# <property name="nailgun.home" value="${basedir}/tool/nailgun"/>
property :name => "nailgun.home", :value => "#{basedir}/tool/nailgun"



#puts "Yeah #{RAW::ApacheAnt::Main.ant_version[/\d.\d.\d./]}"

# Execute
#build :_gu_internal_
#build :jar_complete
#build :clean
build :extract_rdocs
#build :compile

