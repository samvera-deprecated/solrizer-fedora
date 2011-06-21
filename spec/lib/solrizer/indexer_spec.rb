require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'solrizer'
require "solrizer/fedora"


describe Solrizer::Fedora::Indexer do
  
  before(:all) do
    
    unless defined?(Rails) and defined?(RAILS_ENV)
      Object.const_set("Rails", String)
      Rails.stubs(:root).returns(".") #RAILS_ROOT = "."
      RAILS_ENV = "test"
    end
    
    unless defined?(Blacklight)
      Object.const_set("Blacklight", String )
    end
  end
  
  before(:each) do
     
       @extractor = mock("Extractor")
       @extractor.stubs(:html_content_to_solr).returns(@solr_doc)
       @solr_doc = Hash.new
       Solrizer::Extractor.expects(:new).returns(@extractor)
  
  end
    
  after(:all) do
    if Blacklight == String
      Object.send(:remove_const,:Blacklight)
    end
  end

  describe "#new" do
    it "should return a URL from solr_config if the config has a :url" do
      Blacklight.stubs(:solr_config).returns({:url => "http://foo.com:8080/solr"})
      @indexer = Solrizer::Fedora::Indexer.new
      @indexer.solr.uri.to_s.should == "http://foo.com:8080/solr/"
    end
     
    it "should return a URL from solr_config if the config has a 'url' " do
      Blacklight.stubs(:solr_config).returns({'url' => "http://foo.com:8080/solr"})
      @indexer = Solrizer::Fedora::Indexer.new
      @indexer.solr.uri.to_s.should == "http://foo.com:8080/solr/"
    end
     
    it "should raise and error if there is not a :url or 'url' in the config hash" do
      Blacklight.stubs(:solr_config).returns({'boosh' => "http://foo.com:8080/solr"})
      lambda { Solrizer::Fedora::Indexer.new }.should raise_error(URI::InvalidURIError)         
    end
      
    it "should return a fulltext URL if solr_config has a fulltext url defined" do
      Blacklight.stubs(:solr_config).returns({'fulltext' =>{ 'url' => "http://fulltext.com:8080/solr"}, 'default' =>{ 'url' => "http://default.com:8080/solr"}})
      @indexer = Solrizer::Fedora::Indexer.new(:index_full_text => true)
      @indexer.solr.uri.to_s.should == "http://fulltext.com:8080/solr/"
    end
      
    it "should gracefully handle when index_full_text is true but there is no fulltext in the configuration" do
      Blacklight.stubs(:solr_config).returns({'default' =>{ 'url' => "http://foo.com:8080/solr"}})
      @indexer = Solrizer::Fedora::Indexer.new(:index_full_text => true)
      @indexer.solr.uri.to_s.should == "http://foo.com:8080/solr/"
    end
    
    it "should return a fulltext URL if solr_config has a default url defined" do
      Blacklight.stubs(:solr_config).returns({'default' =>{ 'url' => "http://foo.com:8080/solr"}})
      @indexer = Solrizer::Fedora::Indexer.new(:index_full_text => false)
      @indexer.solr.uri.to_s.should == "http://foo.com:8080/solr/"
    end
      
    it "should find the solr.yml even if Blacklight is not loaded" do 
         Object.const_set("Blacklight_temp", Blacklight )
         Object.send(:remove_const, :Blacklight)
         YAML.stubs(:load).returns({'test' => {'url' => "http://thereisnoblacklightrunning.edu:8080/solr"}})
         ENV["environment"]="test"
         @indexer = Solrizer::Fedora::Indexer.new
         Object.const_set("Blacklight", Blacklight_temp )  
         ENV["environment"]=nil
    end
      
    it "should find the solr.yml even if Blacklight is not loaded and RAILS is not loaded" do 
          Object.const_set("Blacklight_temp", Blacklight )
          Object.send(:remove_const, :Blacklight)
          Object.const_set("Rails_temp", Rails)
          Object.send(:remove_const, :Rails)
          YAML.stubs(:load).returns({'development' => {'url' => "http://noblacklight.norails.edu:8080/solr"}})
          @indexer = Solrizer::Fedora::Indexer.new  
          Object.const_set("Blacklight", Blacklight_temp )
          Object.const_set("Rails", Rails_temp)
    end    
  end     
end
    
