require 'spec_helper'

describe FinishTaskWorker do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "finish a task" do
    @task = FactoryGirl.create :analyze_task
    @worker = FinishTaskWorker.new
    Task.should_receive(:find_by_id).and_return(@task)
    @task.should_receive(:finish!).and_return(true)
    @worker.perform(@task.id).should eq true
  end

  it "dupe finish a task raises no error" do
    @task = FactoryGirl.create :analyze_task
    @worker = FinishTaskWorker.new
    Task.should_receive(:find_by_id).and_return(@task)
    @task.should_receive(:finish!).and_raise(StateMachine::InvalidTransition.new(@task, Task.state_machines[:status], :finish))
    @worker.perform(@task.id).should eq true
  end

end
