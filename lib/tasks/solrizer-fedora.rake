require 'jettywrapper'
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

namespace :solrizer do
  
  namespace :fedora  do
    desc 'Index a fedora object of the given pid.'
    task :solrize => :environment do 
      index_full_text = ENV['FULL_TEXT'] == 'true'
      if ENV['PID']
        puts "indexing #{ENV['PID'].inspect}"
        solrizer = Solrizer::Fedora::Solrizer.new :index_full_text=> index_full_text
        solrizer.solrize(ENV['PID'])
        puts "Finished shelving #{ENV['PID']}"
      else
        puts "You must provide a pid using the format 'solrizer::solrize_object PID=sample:pid'."
      end
    end
  
    desc 'Index all objects in the repository.'
    task :solrize_objects => :environment do
      index_full_text = ENV['FULL_TEXT'] == 'true'
      if ENV['INDEX_LIST']
        @@index_list = ENV['INDEX_LIST']
      end
    
      puts "Re-indexing Fedora Repository."
      puts "Fedora URL: #{ActiveFedora.fedora_config[:url]}"
      puts "Fedora Solr URL: #{ActiveFedora.solr_config[:url]}"
      puts "Blacklight Solr Config: #{Blacklight.solr_config.inspect}"
      puts "Doing full text index." if index_full_text
      solrizer = Solrizer::Fedora::Solrizer.new :index_full_text=> index_full_text
      solrizer.solrize_objects
      puts "Solrizer task complete."
    end  
    
    RSpec::Core::RakeTask.new(:rspec) do |t|
      t.pattern = 'spec/**/*_spec.rb'
      #t.spec_files = FileList['spec/**/*_spec.rb']
      t.rcov = true
      t.rcov_opts = lambda do
        IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end
    
  end
  
end
