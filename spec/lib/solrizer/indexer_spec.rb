require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'solrizer'
require "solrizer/fedora"


describe Solrizer::Fedora::Indexer do
  
  
  before(:each) do
     
       @extractor = mock("Extractor")
       @extractor.stubs(:html_content_to_solr).returns(@solr_doc)
       @solr_doc = Hash.new
       Solrizer::Extractor.expects(:new).returns(@extractor)
  
  end

  describe "#new" do
    describe "creates a connection to solr" do
      describe "from blacklight config" do
        before do
          Object.const_set("Blacklight", String )
          Blacklight.stubs(:solr_config).returns({:url=>'http://fake:8888/solr/dev', :read_timeout=>121, :open_timeout => 122})
        end
        after do
          Object.send(:remove_const,:Blacklight)
        end
        it "should set url and timeout properties" do
          RSolr.expects(:connect).with({:url=>'http://fake:8888/solr/dev', :read_timeout=>121, :open_timeout => 122})
          Solrizer::Fedora::Indexer.new
        end
        it "should raise and error if there is not a :url in the config hash" do
          Blacklight.stubs(:solr_config).returns({:boosh => "http://foo.com:8080/solr"})
          lambda { Solrizer::Fedora::Indexer.new }.should raise_error(URI::InvalidURIError)         
        end
          
        it "should return a fulltext URL if solr_config has a fulltext url defined" do
          Blacklight.stubs(:solr_config).returns({:fulltext =>{ 'url' => "http://fulltext.com:8080/solr"}, :default =>{ 'url' => "http://default.com:8080/solr"}})
          @indexer = Solrizer::Fedora::Indexer.new(:index_full_text => true)
          @indexer.solr.uri.to_s.should == "http://fulltext.com:8080/solr/"
        end
          
        it "should gracefully handle when index_full_text is true but there is no fulltext in the configuration" do
          Blacklight.stubs(:solr_config).returns({:default =>{ 'url' => "http://foo.com:8080/solr"}})
          @indexer = Solrizer::Fedora::Indexer.new(:index_full_text => true)
          @indexer.solr.uri.to_s.should == "http://foo.com:8080/solr/"
        end
        
        it "should return a fulltext URL if solr_config has a default url defined" do
          Blacklight.stubs(:solr_config).returns({:default =>{ 'url' => "http://foo.com:8080/solr"}})
          @indexer = Solrizer::Fedora::Indexer.new(:index_full_text => false)
          @indexer.solr.uri.to_s.should == "http://foo.com:8080/solr/"
        end
      end
    end
     
      
    describe "in a rails application" do
      before do 
        Object.const_set("Rails", String)
        Rails.stubs(:root).returns(".")
        Rails.stubs(:env).returns("test")
      end
      after do
        Object.send(:remove_const, :Rails)
      end
      it "should find the solr.yml even if Blacklight is not loaded" do 
        YAML.stubs(:load).returns({'test' => {'url' => "http://thereisnoblacklightrunning.edu:8080/solr"}})
        @indexer = Solrizer::Fedora::Indexer.new
      end
    end
      
    it "should find the solr.yml even if Blacklight is not loaded and RAILS is not loaded" do 
      YAML.stubs(:load).returns({'development' => {'url' => "http://noblacklight.norails.edu:8080/solr"}})
      @indexer = Solrizer::Fedora::Indexer.new  
    end    
  end     
end
    
