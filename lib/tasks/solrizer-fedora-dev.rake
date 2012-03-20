require 'jettywrapper'
require 'rspec/core/rake_task'

APP_ROOT = File.expand_path("../..",File.dirname(__FILE__))
desc "Task to execute builds on a Hudson Continuous Integration Server."
task :hudson do
  if (ENV['RAILS_ENV'] == "test")  
    require "jettywrapper"
    jetty_params = { 
      :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'), 
      :quiet => false, 
      :jetty_port => 8983, 
      :solr_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/solr/test-core'),
      :fedora_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/fedora/default'),
      :startup_wait => 25
    }
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["doc"].invoke
      Rake::Task["solrizer:fedora:rspec"].invoke
    end
    raise "test failures: #{error}" if error
  else
    system("rake hudson RAILS_ENV=test")
  end
end

# Use yard to build docs
begin
  require 'yard'
  require 'yard/rake/yardoc_task'
  project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
  doc_destination = File.join(project_root, 'doc')

  YARD::Rake::YardocTask.new(:doc) do |yt|
    yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                 [ File.join(project_root, 'README.textile') ]
    yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
  end
rescue LoadError
  desc "Generate YARD Documentation"
  task :doc do
    abort "Please install the YARD gem to generate rdoc."
  end
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  # spec.libs << 'lib' << 'spec'
  # spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
#  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

# task :spec => :check_dependencies

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "solrizer #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

