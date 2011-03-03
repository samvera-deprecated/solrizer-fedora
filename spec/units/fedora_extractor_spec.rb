require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'solrizer'

describe Solrizer::Fedora::Extractor do
  
  before(:all) do
    @extractor = Solrizer::Extractor.new
  end
  
  describe "extract_rels_ext" do 
    it "should extract the content model of the RELS-EXT datastream of a Fedora object and set hydra_type using hydra_types mapping" do
      rels_ext = fixture("rels_ext_cmodel.xml")
      result = @extractor.extract_rels_ext( rels_ext )
      result[:cmodel_t].sort.should == ["info:fedora/afmodel:DCDocument", "info:fedora/afmodel:JP2Document", "info:fedora/afmodel:SaltDocument", "info:fedora/fedora-system:ContentModel-3.0"]
      result[:hydra_type_t].sort.should == ["dc_document", "jp2_document", "salt_document"]
    end
  end
  
  describe "extract_hydra_types" do 
    it "should extract the hydra_type of a Fedora object" do
      rels_ext = fixture("rels_ext_cmodel.xml")
      result = @extractor.extract_rels_ext( rels_ext )
      result[:hydra_type_t].sort.should == ["dc_document", "jp2_document", "salt_document"]
    end
  end
  
end