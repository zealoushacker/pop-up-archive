class Tasks::TranscodeTask < Task

  after_commit :create_transcode_job, :on => :create

  def finish_task
    return unless audio_file
    audio_file.check_transcode_complete
  end

  def audio_file
    self.owner
  end

  def format
    extras['format']
  end

  def label
    self.id
  end

  def destination
    extras['destination'] || owner.try(:destination, {
      storage: storage,
      version: format
    })
  end

  def create_transcode_job
    j = create_job do |job|
      job.job_type    = 'audio'
      job.original    = original
      job.priority    = 4
      job.retry_delay = 3600
      job.retry_max   = 24
      job.add_task({
        task_type: 'transcode',
        result:    destination,
        call_back: call_back_url,
        options:   extras,
        label:     label
      })
    end
  end

end
