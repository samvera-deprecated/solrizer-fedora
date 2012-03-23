# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "solrizer/fedora/version"

Gem::Specification.new do |s|
  s.name        = "solrizer-fedora"
  s.version     = Solrizer::Fedora::VERSION
  s.authors = ["Matt Zumwalt"]
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

  s.add_dependency('active-fedora', '~> 4.0.0.rc15') 
  s.add_development_dependency('jettywrapper', '>=1.1.0')
  s.add_development_dependency('rdoc')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
