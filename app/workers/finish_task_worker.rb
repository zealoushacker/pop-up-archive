# encoding: utf-8

class FinishTaskWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 25

  def perform(task_id)
    ActiveRecord::Base.connection_pool.with_connection do
      task = Task.find_by_id(task_id)
      begin
        task.finish! if task
      rescue StateMachine::InvalidTransition => err
        logger.warn "FinishTaskWorker: StateMachine::InvalidTransition: task: #{task_id}, err: #{err.message}"
      end
      true
    end
  end

end
