require 'spec_helper'

describe FeedUpdateWorker do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "processes a url" do
    @collection = FactoryGirl.create :collection
    @worker = FeedUpdateWorker.new
    FeedPopUp.should_receive(:update_from_feed).with("http://fakefeed.test", @collection.id).and_return(true)
    @worker.perform("http://fakefeed.test", @collection.id).should eq true
  end

end
