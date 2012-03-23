require 'solrizer/field_mapper.rb'
require 'solrizer/field_name_mapper'

require 'solrizer/fedora/indexer'
require 'solrizer/xml'
require 'solrizer/html'

require 'active_support/core_ext/hash'

module Solrizer::Fedora
  class Solrizer
    ALL_FIELDS = [
      :pid, :label, :fType, :cModel, :state, :ownerId, :cDate, :mDate, :dcmDate, 
      :bMech, :title, :creator, :subject, :description, :contributor,
      :date, :type, :format, :identifier, :source, :language, :relation, :coverage, :rights 
    ]

    attr_accessor :indexer, :index_full_text

    #
    # This method initializes the indexer
    # If passed an argument of :index_full_text=>true, it will perform full-text indexing instead of indexing fields only.
    #
    def initialize( opts={} )
      @@index_list = false unless defined?(@@index_list)
      if opts[:index_full_text] == true || opts[:index_full_text] == "true"
        @index_full_text = true 
      else
        @index_full_text = false 
      end
      @indexer = Indexer.new( :index_full_text=>@index_full_text )
    end

    # Solrize the given Fedora object's full-text and facets into the search index
    #
    # @param [String or ActiveFedora::Base] obj the object to solrize
    # @param [Hash] opts optional parameters
    # @example Suppress errors using :suppress_errors option
    #   solrizer.solrize("my:pid", :suppress_errors=>true)
    def solrize( obj, opts={} )
      # retrieve the Fedora object based on the given unique id
        
      begin
        
        start = Time.now
        logger.debug "SOLRIZER Retrieving object #{obj} ..."


        if obj.kind_of? ActiveFedora::Base
          # do nothing
        elsif obj.kind_of? String
          obj = Repository.get_object( obj )
        elsif obj.respond_to? :pid
          obj = Repository.get_object( obj.pid )
        else
          raise "you must pass either a ActiveFedora::Base, Fedora::RepositoryObject, or a String.  You submitted a #{obj.class}"
        end
          
            obj_done = Time.now
            obj_done_elapse = obj_done - start
            logger.debug  " completed. Duration: #{obj_done_elapse}"
            
           logger.debug "\t Indexing object #{obj.pid} ... "
           # add the keywords and facets to the search index
           index_start = Time.now
           indexer.index( obj )
           
           index_done = Time.now
           index_elapsed = index_done - index_start
           
            logger.debug "completed. Duration:  #{index_elapsed} ."
          
        
      rescue Exception => e
          if opts[:suppress_errors] 
            logger.debug "SOLRIZER unable to index #{obj}.  Failed with #{e.inspect}"
          else
            raise e
          end
      end

    end
    
    # Retrieve a comprehensive list of all the unique identifiers in Fedora and 
    # solrize each object's full-text and facets into the search index
    #
    # @example Suppress errors using :suppress_errors option
    #   solrizer.solrize_objects( :suppress_errors=>true )
    def solrize_objects(opts={})
      # retrieve a list of all the pids in the fedora repository
      num_docs = 1000000   # modify this number to guarantee that all the objects are retrieved from the repository
      puts "WARNING: You have turned off indexing of Full Text content.  Be sure to re-run indexer with @@index_full_text set to true in main.rb" if index_full_text == false

      if @@index_list == false
        solrize_from_fedora_search(opts) 
      else
        solrize_from_csv
      end
    end

    def solrize_from_fedora_search(opts)
      connections.each do |conn|
        conn.search(nil) do |object|
          solrize( object.pid, opts )
        end
      end 
    end

    def solrize_from_csv
      raise ArgumentException, "#{@@index_list} does not exists!" unless File.exists?(@@index_list)
      puts "Indexing from list at #{@@index_list}"
      CSV.foreach(@@index_list) do |row|
          pid = row[0]
          solrize( pid )
      end 
    end

    private
    
    def connections
      if ActiveFedora.config.sharded?
        return ActiveFedora.config.credentials.map { |cred| ActiveFedora::RubydoraConnection.new(cred).connection}
      else
        return [ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials).connection]
      end
    end
      

  end #class
end #module
