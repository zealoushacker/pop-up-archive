require 'spec_helper'

describe Tasks::DetectDerivativesTask do
  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) do 
    @audio_file = FactoryGirl.create :audio_file
    @urls = AudioFileUploader.version_formats.keys.inject({}) do |h, k|
      h[k] = { url: @audio_file.file.send(k), detected_at: nil }
      h
    end

    @task = Tasks::DetectDerivativesTask.new(owner: @audio_file, identifier: 'detect_derivatives')
    @task.urls = @urls
    @task.save!
  end

  it "should be valid with defaults" do
    task = Tasks::DetectDerivativesTask.new(owner: @audio_file, identifier: 'detect_derivatives')
    task.urls = @urls
   
    task.owner.should eq @audio_file
    task.identifier.should eq 'detect_derivatives'
    task.should be_valid
    task.urls.should_not be_nil
    task.urls.keys.sort.should eq ['mp3', 'ogg']
  end

  it "should have url info as hashes" do
    @task.urls.values.each{|v| v.should be_an_instance_of(HashWithIndifferentAccess) }
  end

  it "should have audio_file owner" do
    @task.owner.should_not be_nil
    @task.owner.should eq @task.audio_file
  end

  it "should list versions" do 
    @task.versions.sort.should eq ['mp3', 'ogg']
  end

  it "should get info for version" do 
    @task.version_info('mp3').should_not be_nil
    @task.version_info('mp3').keys.sort.should eq ['detected_at', 'url']
  end

  it "should should be incomplete when created" do
    @task.should_not be_all_detected
  end

  it "should should be complete when all detected" do
    @task.urls.each{|u, i| i['detected_at'] = DateTime.now }
    @task.save!
    @task.should be_all_detected
  end

  it "should mark detected" do
    @task.version_info('mp3')['detected_at'].should be_nil
    @task.mark_version_detected('mp3')
    @task.version_info('mp3')['detected_at'].should_not be_nil
  end

  it "should finish if all detected" do
    @task.should_not be_complete
    @task.finish_if_all_detected
    @task.urls.each{|u, i| i['detected_at'] = DateTime.now}
    @task.finish_if_all_detected
    @task.should be_complete
  end

  it "should call a worker to check urls" do
    @task.stub(:start_worker).and_return(1)

    job_ids = @task.start_detective
    job_ids.should_not be_nil
    job_ids.length.should eq 2
  end

end
