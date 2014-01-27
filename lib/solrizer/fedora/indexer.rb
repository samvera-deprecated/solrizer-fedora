require 'rsolr'
require 'solrizer/extractor'
require 'solrizer/fedora/repository'

module Solrizer::Fedora
class Indexer  
  # The instance of solr that updates will be written to
  attr_accessor :solr
  
  # The extractor to use.  This is usually Solrizer::Extractor 
  attr_accessor :extractor
  
  # [Boolean or "true" or "false"] tells the indexer whether to index full text or just field values 
  attr_accessor :index_full_text

  #
  # This method performs initialization tasks
  #
  def initialize( opts={} )
    @@index_list = false unless defined?(@@index_list)
    @extractor = ::Solrizer::Extractor.new
    
    if opts[:index_full_text] == true || opts[:index_full_text] == "true"
      @index_full_text = true 
    else
      @index_full_text = false 
    end
    
    connect
  end

  #
  # This method connects to the Solr instance. It looks to see if Blacklight is loaded first for the 
  # Blacklight.solr_config. If not loaded, it then looks for the Rails.root.to_s/config/solr.yaml file and loads
  # it to get the solr url. The configuration strucuture can take both the 
  # { "development" => {"default" => { "url" => "http://localhost"}, "fulltext" => { "url" => "http://localhost"} }}
  # or { "development"=>{"url"=>"http://localhost" }}
  # Can also take Blacklight.solr_config["url"] and Blacklight.solr_config[:url] 
  #
  # If you want to specify a timeout for solr, provide these keys:
  #   :read_timeout=>120, :open_timeout => 120
  #

  def connect
    if defined?(Blacklight)
      solr_config = Blacklight.solr_config
    elsif defined?(Rails.root.to_s)
      solr_config = load_rails_config
    else
      solr_config = load_fallback_config
    end
    
    if index_full_text == true && solr_config.has_key?(:fulltext) && solr_config[:fulltext].has_key?('url')
      solr_config[:url] = solr_config[:fulltext]['url']
    elsif solr_config.has_key?(:default) && solr_config[:default].has_key?('url')
      solr_config[:url] = solr_config[:default]['url']
    elsif !solr_config.has_key?(:url)
      raise "Unable to find a solr url in the config file"
    end

    @solr = RSolr.connect solr_config
  
  rescue RuntimeError => e
    logger.debug "Unable to establish SOLR Connection with #{solr_config.inspect}.  Failed with #{e.message}"
    raise  URI::InvalidURIError
  end


  def load_rails_config
    config_path = File.join(Rails.root.to_s, "config", "solr.yml")
    yaml = YAML.load(File.open(config_path))
    solr_config = yaml[Rails.env].symbolize_keys
    logger.debug solr_config.inspect
    solr_config
  end

  def load_fallback_config
    config_path = File.join("config","solr.yml")
    unless File.exist?(config_path)
      config_path = File.join(File.dirname(__FILE__), "..", "..", "..", "config", "solr.yml")
    end
    logger.debug "SOLRIZER: reading config from " + config_path.inspect 
    yaml = YAML.load(File.open(config_path))
  
    if ENV["environment"].nil?
      environment = "development"
    else
      environment = ENV["environment"]
    end #if

    solr_config = yaml[environment].symbolize_keys
    logger.debug "SOLRIZER solr_config:" + solr_config.inspect
    solr_config
  end

   #
  # This method generates the month and day facets from the date_t in solr_doc
  #
  
  def generate_dates(solr_doc)
    
    # This will check for valid dates, but it seems most of the dates are currently invalid....
    #date_check =  /^(19|20)\d\d([- \/.])(0[1-9]|1[012])\2(0[1-9]|[12][0-9]|3[01])/

   #if there is not date_t, add on with easy-to-find value
   if solr_doc[:date_t].nil?
        ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :date_t, "9999-99-99")
   end #if

    # Grab the date value from date_t regardless of wheter it is inside of an array
    # then convert it to a Date object
    date_value =    solr_doc[:date_t]
    if date_value.kind_of? Array
      date_value = date_value.first
    end
    date_obj = Date._parse(date_value)
    
    if date_obj[:mon].nil? 
       ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :month_facet, "99")
    elsif 0 < date_obj[:mon] && date_obj[:mon] < 13
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :month_facet, date_obj[:mon].to_s.rjust(2, '0'))
    else
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :month_facet, "99")
    end
      
    if  date_obj[:mday].nil?
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :day_facet, "99")
    elsif 0 < date_obj[:mday] && date_obj[:mday] < 32   
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :day_facet, date_obj[:mday].to_s.rjust(2, '0'))
    else
       ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :day_facet, "99")
    end
    
    return solr_doc
        
  end 
  
  #
  # This method creates a Solr-formatted XML document
  #
  def create_document( obj )        
    
    solr_doc = Hash.new
    
    model_klazz_array = ActiveFedora::ContentModel.known_models_for( obj )
    model_klazz_array.delete(ActiveFedora::Base)
    
    # If the object was passed in as an ActiveFedora::Base, call to_solr in order to get the base field entries from ActiveFedora::Base
    # Otherwise, the object was passed in as a model instance other than ActiveFedora::Base,so call its to_solr method & allow it to insert the fields from ActiveFedora::Base
    if obj.class == ActiveFedora::Base
      solr_doc = obj.to_solr(solr_doc)
      logger.debug "  added base fields from #{obj.class.to_s}"
    else
      solr_doc = obj.to_solr(solr_doc)
      model_klazz_array.delete(obj.class)
      logger.debug "    added base fields from #{obj.class.to_s} and model fields from #{obj.class.to_s}"
    end
   
    # Load the object as an instance of each of its other models and get the corresponding solr fields
    # Include :model_only=>true in the options in order to avoid adding the metadata from ActiveFedora::Base every time.
    model_klazz_array.each do |klazz|
      instance = obj.adapt_to(klazz)
      solr_doc = instance.to_solr(solr_doc, :model_only=>true)
      logger.debug "  added solr fields from #{klazz.to_s}"
    end
    
    ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :id_t, "#{obj.pid}" )
    ::Solrizer::Extractor.insert_solr_field_value(solr_doc, :id, "#{obj.pid}" ) unless solr_doc[:id]
    
    return solr_doc
  end

  #
  # This method adds a document to the Solr search index
  #
  def index( obj )
    solr.add( create_document( obj ) )
    #solr.commit
    logger.warn "not committing"
  end
  def commit
    solr.commit
  end
  

  private :connect

end
end
