$LOAD_PATH.push(File.dirname(__FILE__) + '/../lib')
require 'raw'
# require 'build_properties'

class JrubyBuild < RAW::AntProject
  
  RESOURCE_DIR = File.join(FileUtils::pwd, '..', 'spec', 'resources')
  ANT_HOME = File.join(RESOURCE_DIR, 'apache-ant-1.7.1')
  
  RAW::RAWClassLoader.load_ant_libs ANT_HOME

  # <project basedir="." default="jar" name="JRuby">
  def initialize
    super({ :basedir => '/Users/mjohann/projects/jruby',
        :name => 'JRuby',
        :logger => Logger.new(STDOUT),
        :loglevel => Logger::DEBUG,
        :default => 'jar',
        :anthome => @ant_home})
    
    # <import file="netbeans-ant.xml" optional="true"/>
    # _import because import is a jruby key word
    # _import(:file => 'netbeans-ant.xml', :optional => true)

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
  end # initialize

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
    def init
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

    def extract_rdocs
      init
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

    def prepare
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
    def check_for_optional_java4_packages
      init
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

    def check_for_optional_packages
      check_for_optional_java4_packages # TODO if jdk1.5+
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
    def compile_tasks
      prepare # TODO depends implementing
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
    def compile_annotation_binder
      mkdir :dir => @base_dir + '/src_gen'
      javac(:destdir => @jruby_classes_dir,
            :debug => true,
            :srcdir => @src_dir,
            :sourcepath => '',
            :classpath => 'build.classpath',
            :source => '${javac.version}',
            :target => '${javac.version}',
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
    def compile_jruby
      compile_tasks
      compile_annotation_binder
      check_for_optional_packages

      apt(:factory => 'org.jruby.anno.AnnotationBinder',
          :destdir => @jruby_classes_dir,
          :debug => true,
          :source => '${javac.version}',
          :target => '${javac.version}',
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
    def compile
      # Compile the source files for the project.
      compile_jruby
    end
    #<target name="generate-method-classes" depends="compile">
    #  <available file="src_gen/annotated_classes.txt" property="annotations.changed"/>
    #  <antcall target="_gmc_internal_"/>
    #</target>
    def generate_method_classes
      available(:file => 'src_gen/annotated_classes.txt', :property => 'annotations.changed')
      _gmc_internal_ if @annotations_changed # TODO implement asap
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
    def _gmc_internal_
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
           :source => '${javac.version}',
           :target => '${javac.version}',
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
    def generate_unsafe
      available :file => @jruby_classes_dir + '/org/jruby/util/unsafe/GeneratedUnsafe.class', :property => 'unsafe.not.needed'
      _gu_internal_
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
    def _gu_internal_
      echo :message => 'Generating unsafe impl...'
      _java(:classname => 'org.jruby.util.unsafe.UnsafeGenerator', :fork => true, :failonerror => true) do
        classpath :refid => 'build.classpath'
        classpath :path => @jruby_classes_dir
        # uncomment this line when building on a JVM with invokedynamic
        # jvmarg :line => '-XX:+InvokeDynamic'
        arg :value => 'org.jruby.util.unsafe'
        arg :value => @jruby_classes_dir + '/org/jruby/util/unsafe'
      end
    end
    #<target name="jar-jruby" depends="generate-method-classes, generate-unsafe" unless="jar-up-to-date">
    #    <!-- TODO: Unfortunate dependency on ruby executable, and ruby might
    #         not be present on user's side, so we ignore errors caused by that. -->
    #    <exec executable="ruby" dir="${basedir}" failifexecutionfails="false" resultproperty="snapshot.result" errorproperty="snapshot.error">
    #      <arg value="tool/snapshot.rb"/>
    #      <arg value="${jruby.classes.dir}/org/jruby/jruby.properties"/>
    #    </exec>
    #
    #    <jar destfile="${lib.dir}/jruby.jar" compress="false">
    #      <fileset dir="${jruby.classes.dir}"/>
    #      <zipfileset src="${build.lib.dir}/asm-3.0.jar"/>
    #      <zipfileset src="${build.lib.dir}/asm-commons-3.0.jar"/>
    #      <zipfileset src="${build.lib.dir}/asm-util-3.0.jar"/>
    #      <zipfileset src="${build.lib.dir}/asm-analysis-3.0.jar"/>
    #      <zipfileset src="${build.lib.dir}/asm-tree-3.0.jar"/>
    #      <zipfileset src="${build.lib.dir}/bytelist-1.0.1.jar"/>
    #      <zipfileset src="${build.lib.dir}/constantine.jar"/>
    #      <zipfileset src="${build.lib.dir}/jvyamlb-0.2.5.jar"/>
    #      <zipfileset src="${build.lib.dir}/jline-0.9.93.jar"/>
    #      <zipfileset src="${build.lib.dir}/jcodings.jar"/>
    #      <zipfileset src="${build.lib.dir}/joni.jar"/>
    #      <zipfileset src="${build.lib.dir}/jna-posix.jar"/>
    #      <zipfileset src="${build.lib.dir}/jna.jar"/>
    #      <zipfileset src="${build.lib.dir}/joda-time-1.5.1.jar"/>
    #      <zipfileset src="${build.lib.dir}/dynalang-0.3.jar"/>
    #      <manifest>
    #        <attribute name="Built-By" value="${user.name}"/>
    #        <attribute name="Main-Class" value="org.jruby.Main"/>
    #      </manifest>
    #    </jar>
    #</target>
    def jar_jruby
      exec(:executable => 'ruby',
              :dir => @base_dir,
              :failifexecutionfails => false,
              :resultproperty => 'snapshot.result',
              :errorproperty => 'snaptshot.error') do
        arg :value => 'tool/snapshot.rb'
        arg :value => @jruby_classes_dir + '/org/jruby/jruby.properties'
      end
    end
end

raw = JrubyBuild.new
raw.compile_jruby