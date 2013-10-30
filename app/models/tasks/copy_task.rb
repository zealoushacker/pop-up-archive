class Tasks::CopyTask < Task

  attr_accessor :should_process
  @should_process = false

  after_commit :create_copy_job, :on => :create
  after_commit :start_processing, :on => :update

  def finish_task
    return unless owner
    result_path = URI.parse(extras['destination']).path
    new_storage_id = storage_id || extras['storage_id'].to_i

    # set the file on the owner, and the storage as the upload_to
    owner.update_file!(File.basename(result_path), new_storage_id)
    self.should_process = true
  end

  def create_copy_job
    j = create_job do |job|
      job.job_type    = 'audio'
      job.original    = original
      job.retry_delay = 3600 # 1 hour
      job.retry_max   = 24 # try for a whole day
      job.priority    = 1

      job.add_task({
        task_type: 'copy',
        label:     self.id,
        result:    destination,
        call_back: call_back_url
      })
    end
  end

  def start_processing
    return unless should_process
    self.owner(true).analyze_audio
    self.owner(true).transcode_audio
    self.owner(true).transcribe_audio
    self.should_process = false
  end

  def call_back_url
    extras['call_back_url'] || owner.try(:call_back_url)
  end

  def destination
    extras['destination'] || owner.try(:destination, {
      storage: storage
    })
  end

  def original
    extras['original'] || owner.try(:original)
  end

end
