# encoding: utf-8

class UpdateIndexWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 25

  def perform(class_name, object_id)
    ActiveRecord::Base.connection_pool.with_connection do
      obj = class_name.constantize.find_by_id(object_id)

      if obj && obj.respond_to?(:update_index)
        obj.update_index
      end

      true
    end
  end

end
