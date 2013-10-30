require 'spec_helper'

describe Tasks::TranscribeTask do

  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) do
    @audio_file = FactoryGirl.create :audio_file
    @task = Tasks::TranscribeTask.new(owner: @audio_file, identifier: 'ts_all', extras: {original: "http://fakeurl.dev" } )
  end

  context "transcripts" do

    it "should process creating a transcript from JSON" do
      json = '[{"start_time":0,"end_time":9,"text":"from Wednesday January 30th 2013 the following is a replay of the radio doctor daily session in North Carolina House of Representatives","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"tractor seat visitors","confidence":0.8770266}]'
      trans = @task.process_transcript(json)
      trans.timed_texts.count.should == 2
    end

    it "should set text properly" do
      json = '[{"start_time":0,"end_time":9,"text":"three","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"four","confidence":0.8770266},{"start_time":16,"end_time":25,"text":"five","confidence":0.8770266}]'
      trans = @task.process_transcript(json)
      trans.timed_texts.count.should == 3
      trans.timed_texts.collect{|t|t.text}.join(" ").should eq "three four five"
    end

    it "should process creating a transcript from JSON and calculate confidence" do
      json = '[{"start_time":0,"end_time":9,"text":"from Wednesday January 30th 2013 the following is a replay of the radio doctor daily session in North Carolina House of Representatives","confidence":1.0},{"start_time":8,"end_time":17,"text":"tractor seat visitors","confidence":0.0}]'
      transcript = @task.process_transcript(json)
      transcript.confidence.should eq 0.5
      transcript.set_confidence.should eq 0.5
      transcript.confidence.should eq 0.5
    end

    it "analyzes transcript on task finish" do
      json = '[{"start_time":0,"end_time":9,"text":"from Wednesday January 30th 2013 the following is a replay of the radio doctor daily session in North Carolina House of Representatives","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"tractor seat visitors","confidence":0.8770266}]'

      @task = FactoryGirl.create :transcribe_task
      @task.should_receive(:download_file).and_return(json)
      @task.audio_file.should_receive(:analyze_transcript)
      @task.finish_task
    end

  end

end