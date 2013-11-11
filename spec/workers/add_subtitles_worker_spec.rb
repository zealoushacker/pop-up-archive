require 'spec_helper'

describe AddSubtitlesWorker do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "processes a url" do
    @task = FactoryGirl.create :add_to_amara_task
    @worker = AddSubtitlesWorker.new
    @worker.should_receive(:call_add_to_amara).and_return(true)
    @worker.perform(@task.id).should eq true
  end

end
