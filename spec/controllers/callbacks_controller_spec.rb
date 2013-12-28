require 'spec_helper'
describe CallbacksController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  before :each do
    request.accept = "application/json"
  end

  describe "POST 'create'" do
    before :each do
      @task = FactoryGirl.create :add_to_amara_task, extras: {video_id: 'abcdefg'}

    end

    it "gets random callback from amara" do
      post 'amara', {"video_id"=>"abcdefg", "event"=>'subs-random'}
      response.code.should eq "200"
      response.should be_success
    end

    it "gets new callback from amara" do
      post 'amara', {"video_id"=>"abcdefg", "event"=>'subs-new'}
      response.code.should eq "202"
      response.should be_success
    end

    it "gets approved callback from amara" do
      post 'amara', {"video_id"=>"abcdefg", "event"=>'subs-approved'}
      response.code.should eq "202"
      response.should be_success
    end

  end

end
