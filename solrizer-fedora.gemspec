# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "solrizer/fedora/version"

Gem::Specification.new do |s|
  s.name        = "solrizer-fedora"
  s.version     = Solrizer::Fedora::VERSION
  s.authors = ["Matt Zumwalt"]
  s.date = %q{2011-05-20}
  s.description = %q{An extension to projecthydra/solrizer that provides utilities for loading objects from Fedora Repositories and creating solr documents from them.}
  s.email = %q{matt.zumwalt@yourmediashelf.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.textile"
  ]
  s.platform    = Gem::Platform::RUBY
  s.homepage = %q{http://github.com/projecthydra/solrizer-fedora}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{An extension to solrizer that deals with Fedora objects & Repositories}

  s.rubyforge_project = "solrizer-fedora"

  s.add_dependency('solr-ruby', '>= 0.0.6')
  s.add_dependency('active-fedora', '~> 3.1.0') 
  s.add_dependency('rsolr') 
  s.add_dependency('solrizer', '>=1.0.0')
  s.add_dependency('fastercsv') # this is used by solrize_objects when you pass it a csv file of pids
  s.add_dependency('jettywrapper', '>=1.1.0')
  s.add_dependency('activesupport')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
