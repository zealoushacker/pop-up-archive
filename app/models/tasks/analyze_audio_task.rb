class Tasks::AnalyzeAudioTask < Task

  after_commit :create_analyze_job, :on => :create

  def finish_task
    return unless audio_file
    analysis = params[:result_details][:info]
    audio_file.update_attribute(:duration, analysis[:length].to_i)
  end

  def create_analyze_job
    j = MediaMonsterClient.create_job do |job|
      job.job_type    = 'audio'
      job.original    = original
      job.retry_delay = 3600 # 1 hour
      job.retry_max   = 24 # try for a whole day
      job.priority    = 3

      job.add_task({
        task_type: 'analyze',
        label:     self.id,
        call_back: call_back_url
      })
    end
  end

  def call_back_url
    extras['call_back_url'] || audio_file.try(:call_back_url)
  end

  def original
    extras['original'] || audio_file.try(:original)
  end

  def audio_file
    self.owner
  end

end