class Tasks::TranscribeTask < Task

  after_commit :create_transcribe_job, :on => :create

  def finish_task
    return unless audio_file
    connection = Fog::Storage.new(storage.credentials)
    uri        = URI.parse(destination)

    transcript = download_file(connection, uri)
    new_trans  = process_transcript(transcript)

    # if new transcript resulted, then call analyze
    audio_file.analyze_transcript if new_trans
  end

  def audio_file
    owner
  end

  def create_transcribe_job
    if start_only?
      j = MediaMonsterClient.create_job do |job|
        job.job_type    = 'audio'
        job.original    = original
        job.priority    = 2
        job.retry_delay = 3600 # 1 hour
        job.retry_max   = 24 # try for a whole day
        job.add_sequence do |seq|
          seq.add_task({task_type: 'cut', options: {length: 60, fade: 0}})
          seq.add_task({
            task_type: 'transcribe',
            result:    destination,
            call_back: call_back_url,
            label:     self.id,
            options:   transcribe_options
          })
        end
      end
    else
      j = MediaMonsterClient.create_job do |job|
        job.job_type = 'audio'
        job.original = original
        job.priority = 3
        job.retry_delay = 3600 # 1 hour
        job.retry_max = 24 # try for a whole day
        job.add_task({
          task_type: 'transcribe',
          result:    destination,
          call_back: call_back_url,
          label:     self.id,
          options:   transcribe_options
        })
      end
    end
  end

  def process_transcript(json)
    return nil if json.blank?

    identifier = Digest::MD5.hexdigest(json)

    if trans = audio_file.transcripts.where(identifier: identifier).first
      logger.debug "transcript #{trans.id} already exists for this json: #{json[0,50]}"
      return false
    end

    trans_json = JSON.parse(json) if json.is_a?(String)
    trans = audio_file.transcripts.build(language: 'en-US', identifier: identifier, start_time: 0, end_time: 0)
    sum = 0.0
    count = 0.0
    trans_json.each do |row|
      tt = trans.timed_texts.build({
        start_time: row['start_time'],
        end_time:   row['end_time'],
        confidence: row['confidence'],
        text:       row['text']
      })
      trans.end_time = tt.end_time if tt.end_time > trans.end_time
      trans.start_time = tt.start_time if tt.start_time < trans.start_time
      sum = sum + tt.confidence.to_f
      count = count + 1.0
    end
    trans.confidence = sum / count if count > 0

    save_transcript(trans)
  end

  def save_transcript(trans)
    # don't save this one if it is less time
    if audio_file.transcripts.where("language = ? AND end_time > ?", trans.language, trans.end_time).exists?
      logger.error "Not saving transcript for audio_file: #{audio_file.id} b/c end time is earlier: #{trans.end_time}"
      return nil
    end
    
    trans.save!
    # delete trans which cover less time
    partials_to_delete = audio_file.transcripts.where("language = ? AND end_time < ?", trans.language, trans.end_time)
    partials_to_delete.each{|t| t.destroy}
    trans
  end

  def transcribe_options
    {
      language:         'en-US',
      chunk_duration:   5,
      overlap:          1,
      max_results:      1,
      profanity_filter: true
    }
  end

  def start_only?
    !!extras['start_only']
  end

  def call_back_url
    extras['call_back_url'] || owner.try(:call_back_url)
  end

  def destination
    suffix = start_only? ? '_ts_start.json' : '_ts_all.json'
    extras['destination'] || owner.try(:destination, {
      storage: storage,
      suffix:  suffix,
      options: { metadata: { 'x-archive-meta-mediatype' => 'data' } }
    })
  end

  def original
    extras['original'] || owner.try(:original)
  end

end
