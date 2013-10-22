class CallbacksController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def amara
    return unless event_name == "subs-approved"
    # figure out what task this is related to
    task = Task.where("extras -> 'video_id' = ?", params[:video_id]).first
    FinishTaskWorker.perform_async(task.id) if task
  end

end
