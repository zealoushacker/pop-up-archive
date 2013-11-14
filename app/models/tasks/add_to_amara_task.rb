class Tasks::AddToAmaraTask < Task

  state_machine :status do
    event :finish do
      transition all => :complete
    end
  end

  after_commit :order_transcript, :on => :create

  def shared_attributes
    ['transcript_url', 'edit_transcript_url']
  end

  def order_transcript
    return if video_id
    logger.debug("AddToAmaraTask #{self.id}: order_transcript start")
    # create the job at amara
    video = create_video
    # save the video_id, which is useful for crafting a url
    self.extras['video_id'] = video.id
    self.save!

    start_add_subtitles_worker

    self
  end

  def create_video
    logger.debug("AddToAmaraTask: create_video start")
    video_response = amara_client.videos.create(new_video)
    video = video_response.object
    logger.debug("AddToAmaraTask amara video created: #{video.inspect}")
    video
  end

  def start_add_subtitles_worker
    return if self.extras['omit_subtitles']
    AddSubtitlesWorker.perform_async(self.id) unless Rails.env.test?
  end

  def add_subtitles
    logger.debug "AddToAmaraTask add_subtitles start"

    video_language = nil
    begin
      video_language = amara_client.videos(video_id).languages(language).get
    rescue Exception => exception
      logger.error "AddToAmaraTask add_subtitles get languages: error: #{exception.class.name}: #{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
    end

    begin
      amara_client.videos(video_id).languages.create(language_code: language, is_original: true) unless video_language
    rescue Exception => exception
      logger.error "AddToAmaraTask add_subtitles create language: error: #{exception.class.name}: #{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
    end

    amara_client.videos(video_id).languages(language).subtitles.create(new_subtitles)

    logger.debug "AddToAmaraTask add_subtitles end"
  end

  def finish_task
    return unless audio_file
    subtitles = get_latest_subtitles
    transcript = load_subtitles(subtitles)
    if transcript
      audio_file.analyze_audio(true)
      notify_user
    end
  end

  def notify_user
    TranscriptCompleteMailer.new_amara_transcript(user, audio_file, audio_file.item).deliver
  end

  def get_latest_subtitles
    r = amara_client.videos(video_id).languages(language).subtitles.get
    r.object
  end

  def load_subtitles(subtitles)
    return nil unless (subtitles && subtitles.subtitles && (subtitles.subtitles.count > 0))

    version = subtitles.version_number.to_i
    return nil if (version.to_i <= self.extras['subtitles_version'].to_i)

    full_language = (audio_file.item.language || 'en-US')
    identifier    = "#{audio_file.id}_#{language}"
    transcript    = audio_file.item.transcripts.build(language: full_language, identifier: identifier, start_time: 0, end_time: 0, confidence: 100)

    subtitles.subtitles.each do |row|
      tt = transcript.timed_texts.build({
        start_time: (row.start.to_i / 1000.00).round,
        end_time:   (row.end.to_i   / 1000.00).round,
        confidence: 100,
        text:       row.text
      })
      transcript.end_time = tt.end_time if ((tt.end_time > transcript.end_time) || (transcript.end_time <= 0))
      transcript.start_time = tt.start_time if ((tt.start_time < transcript.start_time) || (transcript.start_time <= 0))
    end
    transcript.confidence = 100
    self.extras['subtitles_version'] = version
    transcript.save! && self.save!

    transcript
  end

  def audio_file
    owner
  end

  def user
    User.find(user_id) if (user_id.to_i > 0)
  end

  def user_id
    self.extras['user_id']
  end

  def video_id
    self.extras['video_id']
  end

  def video_url
    # audio_file.url(:ogg)
    audio_file.public_url(extension: :ogg)
  end

  def language
    audio_file.item.language ? audio_file.item.language.split('-')[0].downcase : 'en' rescue 'en'
  end

  def team
    self.extras['amara_team']
  end

  def new_video
    options = {
      # duration: audio_file.duration, # don't have this, could get from fixer analysis perhaps?
      team:      team,
      title:     audio_file.filename,
      video_url: video_url,
      primary_audio_language_code: language
    }

    logger.debug "AddToAmaraTask new_video: #{options.inspect}"

    options
  end

  def new_subtitles
    full_language = (audio_file.item.language || 'en-US')
    transcript = audio_file.timed_transcript(full_language)
    srt = transcript.to_srt if transcript

    options = {
      sub_format: 'srt',
      subtitles:  srt
    }
    
    logger.debug "AddToAmaraTask new_subtitles: #{options.inspect}"

    options    
  end

  def amara_client
    @client ||= Amara::Client.new(
      api_key:      ENV['AMARA_KEY'],
      api_username: ENV['AMARA_USERNAME'],
      endpoint:     "https://#{ENV['AMARA_HOST']}/api2/partners"
    )
  end

  def edit_transcript_url
    return '' if video_id.blank?
    "http://#{ENV['AMARA_HOST']}/en/onsite_widget/?config=" + edit_transcript_url_options
  end

  def transcript_url
    return '' if video_id.blank?
    "http://#{ENV['AMARA_HOST']}/en/videos/#{video_id}"
  end

  def edit_transcript_url_options
    URI.encode({
      videoID:           video_id,
      videoURL:          video_url,
      effectiveVideoURL: video_url,
      languageCode:      language
    }.to_json)
  end

end
