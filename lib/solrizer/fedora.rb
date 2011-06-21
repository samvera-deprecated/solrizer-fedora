require "rubygems"
require "solrizer"

# Solrizer::Fedora is an implementation of Solrizer that reads content from Fedora repositories and indexes it into solr.
#
# Note: This module automatically extends Solrizer::Extractor with additional Fedora-specific extractor behaviors from Solrizer::Fedora::Extractor.
module Solrizer::Fedora
  def self.version
    Solrizer::Fedora::VERSION
  end
end
Dir[File.join(File.dirname(__FILE__),"fedora","*.rb")].each {|file| require file }

Solrizer::Extractor.send(:include, Solrizer::Fedora::Extractor)
