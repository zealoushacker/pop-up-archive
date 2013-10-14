class Result; end

class ItemResultsPresenter < BasicObject

  class SearchResult; end

  def initialize(results)
    @results = results
  end

  def results
    @_results ||= @results.map {|result| ItemResultPresenter.new(result) }
  end

  def respond_to?(method)
    method == :results || @results.respond_to?(method)
  end

  def method_missing(method, *args)
    if @results.respond_to?(method)
      @results.send method, *args
    end
  end

  class ItemResultPresenter < BasicObject

    def initialize(result)
      @result = result
    end

    def loaded_from_database?
      !!@_result
    end

    def database_object
      @_result ||= ::Item.find_by_id(id)
    end

    def audio_files
      @_audio_files ||= ::AudioFile.where(item_id: @result.id)
    end

    def highlighted_audio_files
      @_highlighted_audio_files ||= generate_highlighted_audio_files
    end

    def entities
      @_entities ||= build_entities
    end

    def respond_to?(method)
      [:audio_files, :highlighted_audio_files, :entities].include?(method) || @result.respond_to?(method) || database_object.respond_to?(method)
    end

    def method_missing(method, *args)
      if loaded_from_database? && database_object.respond_to?(method)
        return database_object.send method, *args
      end

      if @result.respond_to? method
        @result.send method, *args
      elsif database_object.respond_to? method
        database_object.send method, *args
      end
    end

    def class
      ::Result
    end

    private

    def generate_highlighted_audio_files
      if @result.highlight.present? && @result.highlight.transcript.present?
        lookup = ::Hash[@result.highlight.transcript[0,5].map{|t| [t.gsub(/<\/?em>/, ''), t]}]
      else
        return []
      end
      keys = lookup.keys
      audio_file_presenters = ::Hash.new do |hash, id|
        af = audio_files.find {|af| af.id == id }
        hash[id] = HighlightedAudioFilePresenter.new(af) if af
      end

      if @result.transcripts.present?
        @result.transcripts.select {|transcript| keys.include? transcript.transcript }.each do |transcript|
          audio_file_presenters[transcript.audio_file_id].transcript_array.push({text: lookup[transcript.transcript], start_time: transcript.start_time, end_time: transcript.end_time })
        end
        audio_file_presenters.values
      else
        []
      end
    end

    def build_entities
      [].tap do |results|
        [:confirmed_entities, :high_unconfirmed_entities, :mid_unconfirmed_entities, :low_unconfirmed_entities].each do |ec|
          results.concat @result.send(ec).map {|e| EntityPresenter.new(e) }
        end
      end
    end
  end

  class HighlightedAudioFilePresenter
    attr_reader :id, :url, :filename, :transcript_array, :tasks
    def initialize(audio_file)
      @id = audio_file.id
      @url = audio_file.url
      @filename = audio_file.filename
      @transcript_array = []
    end
  end

  class EntityPresenter
    attr_reader :name, :category, :extra
    def initialize(entity)
      @name = entity.entity
      @category = entity.category
    end

    def class
      ::Entity
    end
  end

end