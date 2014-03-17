require 'spec_helper'

describe FileStorage do

  before {
    SubscriptionPlan.reset_cache
    StripeMock.start
  }
  after { StripeMock.stop }

  context "basics" do

    before(:each) {
      @audio_file = FactoryGirl.create :audio_file
      @image_file = FactoryGirl.create :image_file
    }

    # it "should provide filename for an image file" do
    #   @image_file.file.filename.should eq 'test.jpg'
    #   @audio_file.filename('ogg').should eq 'test.ogg'
    # end

    # it "should provide filename for remote url" do
    #   audio_file = AudioFile.new
    #   audio_file.item = @audio_file.item
    #   audio_file.user = @audio_file.user

    #   audio_file.remote_file_url = "http://www.prx.org/test.wav"
    #   audio_file.filename.should eq 'test.wav'
    #   audio_file.filename('ogg').should eq 'test.ogg'

    #   audio_file.remote_file_url = "http://www.prx.org/test"
    #   audio_file.filename.should eq 'test'
    #   audio_file.filename('ogg').should eq 'test.ogg'
    #   audio_file.filename(nil).should eq 'test'
    # end

    # it "should provide a url" do
    #   @audio_file.url.should eq '/test.mp3'
    # end

  end
end
