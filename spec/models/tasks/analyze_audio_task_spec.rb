require 'spec_helper'

describe Tasks::AnalyzeAudioTask do

  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) do 
    @audio_file = FactoryGirl.create :audio_file
    @task = Tasks::AnalyzeAudioTask.new(owner: @audio_file, extras: { original: "http://test.test/test.wav" })
  end

  it 'callback' do
    @task.call_back_url.should eq @audio_file.call_back_url
    @task.extras['call_back_url'] = 'callback'
    @task.call_back_url.should eq 'callback'
  end

  it 'original' do
    @task.extras['original'] = 'original'
    @task.original.should eq 'original'
    @task.extras.delete('original')
    @task.original.should eq @audio_file.process_file_url
  end

  it 'audio_file' do
    @task.audio_file.should eq @task.owner
  end

  it 'finish_task' do
    @task.results = {"status"=>"complete", "message"=>"analysis complete", "info"=>{"size"=>517115014, "content_type"=>"audio/vnd.wave", "channel_mode"=>"Mono", "bit_rate"=>705, "length"=>5862, "sample_rate"=>44100}, "logged_at"=>"2013-11-11T15:34:21Z"}
    @task.finish_task
    @task.audio_file.duration.should eq 5862
  end

end
