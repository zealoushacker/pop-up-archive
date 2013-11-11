class Admin::TaskList < Admin::Report

  attr_accessor :pending_tasks

  def initialize()
    @pending_tasks = []
    tasks = incomplete_tasks
    tasks.each do |task|
      line = Hash.new
      line[:id] = task.id
      line[:type] = task.type

      unless task.owner == nil
        line[:owner_type] = task.owner.class.name
        line[:owner_id] = task.owner_id

        # this is going to fail when we have collections owned by users and orgs - AK
        audio_file = task.owner.class.joins(item: :collection).find(task.owner_id)
        line[:user_email] = audio_file.user.email
        line[:user_id] = audio_file.user_id

        line[:collection_title] = audio_file.item.collection.title
        line[:collection_id] = audio_file.item.collection_id
        line[:item_id] = audio_file.item_id
        line[:item_title] = audio_file.item.title
      end

      line[:created_at] = task.created_at
      line[:updated_at] = task.updated_at
      line[:status] = task.status
      @pending_tasks << line
    end
  end

  def incomplete_tasks
    Task.includes(:owner).where("tasks.status != 'complete'")
  end

end