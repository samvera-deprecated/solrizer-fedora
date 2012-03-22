require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Solrizer::Fedora::Solrizer do
  
  before(:each) do
    @solrizer = Solrizer::Fedora::Solrizer.new
  end
  
  describe "solrize" do
    it "should trigger the indexer for the provided object" do
      sample_obj = ActiveFedora::Base.new
      @solrizer.indexer.expects(:index).with( sample_obj )
      @solrizer.solrize( sample_obj )
    end
    it "should work with Fedora::FedoraObject objects" do
      mock_object = stub(:pid=>"my:pid", :label=>"my label")
      ActiveFedora::Base.expects(:load_instance).with( mock_object.pid ).returns(mock_object)
      @solrizer.indexer.expects(:index).with( mock_object )
      @solrizer.solrize( mock_object )
    end
    it "should load the object if only a pid is provided" do
      mock_object = mock("my object")
      mock_object.stubs(:pid)
      mock_object.stubs(:label)
      mock_object.stubs(:datastreams).returns({'descMetadata'=>"foo","location"=>"bar"})

      ActiveFedora::Base.expects(:load_instance).with( "_PID_" ).returns(mock_object)
      @solrizer.indexer.expects(:index).with(mock_object)
      @solrizer.solrize("_PID_")
    end

  end

  describe "solrize_objects" do
    describe "when fedora is sharded" do
      before do
        @mock1 = mock("connection1")
        @mock2 = mock("connection2")
        @solrizer.expects(:connections).returns([@mock1, @mock2])
        @mock1.expects(:search).yields(stub('obj', :pid=>'one'))
        @mock2.expects(:search).yields(stub('obj', :pid=>'two'))
      end
      it "should hit all the shards" do
        @solrizer.expects(:solrize).with('one', {})
        @solrizer.expects(:solrize).with('two', {})
        @solrizer.solrize_objects()
      end
    end

    describe "with one connection" do
      before do
        @mock1 = mock("connection1")
        @solrizer.expects(:connections).returns([@mock1])
        @mock1.expects(:search).yields(stub('obj', :pid=>'one'))
      end 
      it "should solrize_objects" do
        @solrizer.expects(:solrize).with('one', {})
        @solrizer.solrize_objects()
      end
      it "should pass optional suppress_errors argument into .solrize method" do
        @solrizer.expects(:solrize).with( 'one', :suppress_errors => true )
        @solrizer.solrize_objects( :suppress_errors => true )
      end
    end
  end
end
