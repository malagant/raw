# Defaults. To override, create a file called build.properties in
#  the same directory and put your changes in that.
module BuildProperties
  @base_dir = '.'
  @src_dir = 'src'
  @test_dir = 'test'
  @lib_dir = 'lib'
  @spec_dir = @base_dir + '/spec'
  @rubyspec_dir = @spec_dir + '/ruby'
  @rails_dir = @test_dir + '/rails'
  @mspec_dir = @spec_dir + '/mspec'
  @rubyspec_1_8_dir = @rubyspec_dir + '/1.8'
  @spec_tags_dir = @spec_dir + '/tags'
  @build_lib_dir = 'build_lib'
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
end
