# encoding: utf-8

class AddSubtitlesWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 25

  def perform(task_id)
    ActiveRecord::Base.connection_pool.with_connection do
      task = Tasks::AddToAmaraTask.find(task_id)
      call_add_to_amara(task)
      true
    end
  end

  def call_add_to_amara(task)
    task.add_subtitles
  end

end
