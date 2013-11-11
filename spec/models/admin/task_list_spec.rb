require 'spec_helper'

describe Admin::TaskList do

  before {
    @task = FactoryGirl.create :analyze_task
    Admin::TaskList.any_instance.stub(:incomplete_tasks).and_return([@task])
    @task_list = Admin::TaskList.new
  }

  it 'initializes' do
    task_list = Admin::TaskList.new
    task_list.should_not be_nil
    task_list.pending_tasks.should_not be_nil
  end

  it 'has list of pending tasks as list of hashes' do
    @task_list.pending_tasks.count.should eq 1
    pt = @task_list.pending_tasks.first
    pt[:id].should eq @task.id
  end

end
