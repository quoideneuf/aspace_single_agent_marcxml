
class SingleAgentMarcXMLAccessionConverter < MarcXMLConverter
  def self.import_types(show_hidden = false)
    [
     {
       :name => "marcxml_accession",
       :description => "Import MARC XML records as Accessions (Single Agent)"
     }
    ]
  end


  # we have to do it this way because the code blocks
  # in converter configurations don't have access to 
  # converter state...would be nice to fix that
  def initialize(input_file)
    super(input_file)

    @agent_uris = []

    @batch.record_filter = ->(record) {
      if record['jsonmodel_type'] == 'accession'
        record['linked_agents'].reject! {|la| !@agent_uris.include?(la[:ref])}
      end


      return true unless record['jsonmodel_type'] == 'agent_person' 

      other = @batch.working_area.find {|rec| rec['jsonmodel_type'] == 'agent_person'}
      if other
        other['names'].concat(record['names'])
        false
      else
        @agent_uris << record['uri']
        true
      end
    }
  end

  def self.instance_for(type, input_file)
    if type == "marcxml_accession"
      self.new(input_file)
    else
      nil
    end
  end

end

# TODO - write some of this into the built-in MarcXMLAccessionConverter
# class's configure method so it can be inherited.
SingleAgentMarcXMLAccessionConverter.configure do |config|

  config["/record"][:obj] = :accession
  config["/record"][:map].delete("//controlfield[@tag='008']")

  # the sketchy way converters are subclassed...
  config.doc_frag_nodes.uniq! 

  # strip mappings that target .notes
  config["/record"][:map].each do |path, defn|
    next unless defn.is_a?(Hash)
    if defn[:rel] == :notes
      config["/record"][:map].delete(path)
    end
  end


  # strip other mappings that target resource-only properties
  [
   "datafield[@tag='536']" # finding_aid_sponsor
  ].each do |resource_only_path|
    config["/record"][:map].delete(resource_only_path)
  end


  # content_description
  %w(250 254 255 256 257 258 306 340 342 343 351 352 500 501 502 504 507 508 511 513 514 518 520 524 530 533 534 535 536 538 544 546 555 562 563 580 581 590 591 592 593 594 595 596 597 598 599).each do |tag|
    config["/record"][:map]["datafield[@tag='#{tag}']"] = -> accession, node {
      accession['_content_descriptions'] ||= {}
      accession['_content_descriptions'][tag] = node.inner_text
    }
  end

  config["/record"][:map]["datafield[@tag='001']"] = SingleAgentMarcXMLAccessionConverter.mix(SingleAgentMarcXMLAccessionConverter.person_template, SingleAgentMarcXMLAccessionConverter.creators_and_sources)

  # This has to be last
  config["/record"][:map]["self::record"] = -> accession, node {

    if accession['_titles']
      accession.title = accession['_titles'].sort.map {|e| e[1]}.join(' ')
    end

    if !accession.title && accession['_fallback_titles'] && !accession['_fallback_titles'].empty?
      accession.title = accession['_fallback_titles'].shift
    end

    if accession.id_0.nil? or accession.id.empty?
      accession.id_0 = "imported-#{SecureRandom.uuid}"
    end

    accession.accession_date = Time.now.to_s.sub(/\s.*/, '')

    if accession['_content_descriptions']
      accession.content_description = accession['_content_descriptions'].sort.map {|e| e[1]}.join(' ')
    end
  }

end
