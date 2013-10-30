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

  def call_back_url
    extras['call_back_url'] || owner.try(:call_back_url)
  end

  def destination
    extras['destination'] || owner.try(:destination, {
      storage: storage,
      version: format
    })
  end

  def original
    extras['original'] || owner.try(:destination)
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

  def create_job
    job_id = nil

    # puts "\n\ntranscode job: " + Thread.current.backtrace.join("\n")

    begin
      new_job = MediaMonsterClient.create_job do |job|
        yield job
      end
      
      logger.debug("create_job: created: #{new_job.inspect}")
      job_id = new_job.id

    rescue Object=>exception
      logger.error "create_job: error: #{exception.class.name}: #{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
      job_id = 1
    end
    job_id
  end

end
