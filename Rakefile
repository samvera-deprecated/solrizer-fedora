require 'rubygems'
require 'rake'

# load rake tasks in lib/tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "solrizer-fedora"
    gem.summary = %Q{An extension to solrizer that deals with Fedora objects & Repositories}
    gem.description = %Q{An extension to projecthydra/solrizer that provides utilities for loading objects from Fedora Repositories and creating solr documents from them.}
    gem.email = "matt.zumwalt@yourmediashelf.com"
    gem.homepage = "http://github.com/projecthydra/solrizer-fedora"
    gem.authors = ["Matt Zumwalt"]
    gem.add_dependency('solr-ruby', '>= 0.0.6')
    gem.add_dependency('active-fedora', '2.2.0.rails3pre1') 
    gem.add_dependency('rsolr') 
    gem.add_dependency('solrizer', '>=1.0.0')
    gem.add_dependency('fastercsv') # this is used by solrize_objects when you pass it a csv file of pids
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

# task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
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
