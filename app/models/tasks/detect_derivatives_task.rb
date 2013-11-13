class Tasks::DetectDerivativesTask < Task

  before_save :serialize_urls

  after_commit :start_detective, :on => :create
  after_commit :finish_if_all_detected, :on => :update

  def serialize_urls
    self.serialize_extra('urls')
  end

  def finish_task
    return unless audio_file
    # mark the audio_file as having processing complete?
    audio_file.update_attribute(:transcoded_at, DateTime.now)
  end

  def urls
    deserialize_extra('urls', {})
  end

  def audio_file
    self.owner
  end

  def versions
    urls.keys.sort
  end

  def version_info(version)
    urls[version]
  end

  def all_detected?
    any_nil = versions.detect{|version| version_info(version)['detected_at'].nil?}
    !any_nil
  end
  
  def mark_version_detected(version)
    vi = version_info(version)
    if (vi && !vi['detected_at'])
      vi['detected_at'] = DateTime.now
      self.save!
    end
  end

  def finish_if_all_detected
    return if complete?
    any_nil = versions.detect{|version| version_info(version)['detected_at'].nil?}
    self.finish! if !any_nil
  end

  def start_detective
    job_ids = []
    versions.each do |version|
      info = version_info(version)
      job_ids << start_worker(version, info['url'])
    end
    job_ids
  end

  def start_worker(version, url)
    CheckUrlWorker.perform_async(id, version, url) unless Rails.env.test?
  end

end
