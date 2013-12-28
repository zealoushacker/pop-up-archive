require 'spec_helper'

describe Tasks::TranscodeTask do
  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) do 
    @audio_file = FactoryGirl.create :audio_file_private
    @format = AudioFileUploader.version_formats['ogg']
    @task = Tasks::TranscodeTask.new(extras: @format, owner: @audio_file, identifier: 'ogg_transcode')
    @task.save!
  end

  it "should set defaults" do
    task = Tasks::TranscodeTask.new()
    task.should be_valid
    task.save!
  end

  it "should have format info in extras" do
    extras = @task.extras.clone
    extras.delete('cbt')
    extras.keys.sort.should eq AudioFileUploader.version_formats['ogg'].keys.sort
    extras.values.sort.should eq AudioFileUploader.version_formats['ogg'].values.collect(&:to_s).sort
  end

  it "should be valid with defaults" do
    task = Tasks::TranscodeTask.new(extras: @format, owner: @audio_file, identifier: 'ogg_transcode')
    task.owner.should eq @audio_file
    task.identifier.should eq 'ogg_transcode'
    task.should be_valid
    task.extras.should_not be_nil
    task.extras.keys.sort.should eq ['bit_rate', 'cbt', 'channel_mode', 'format', 'sample_rate']
  end

  it "should have audio_file owner" do
    @task.owner.should_not be_nil
    @task.owner.should eq @task.audio_file
  end

  it "should get the destination for a format" do
    @task.destination.should start_with('s3://' + ENV['AWS_BUCKET'] + '/untitled.')
    @task.destination.should end_with('.popuparchive.org/test.ogg')
  end

  it "should get the original to be transcoded" do
    @task.original.should start_with('s3://' + ENV['AWS_BUCKET'] + '/untitled.')
    @task.original.should end_with('.popuparchive.org/test.mp3')
  end

  # it "should add transcode task to job" do
  #   job = MediaMonster::Job.new
  #   tasks = @task.add_transcode_task(job, 'test', @task.formats['ogg'])
  #   task = tasks.first
  #   task.task_type.should eq 'transcode'
  #   task.options.should eq @task.formats['ogg']
  #   task.result.should eq @task.destination('ogg')
  #   task.call_back.should eq "http://test.popuparchive.org/api/items/#{@audio_file.item.id}/audio_files/#{@audio_file.id}"
  #   task.label.should eq 'test'
  # end

  it "should create a transcode job" do
    job = MediaMonster::Job.new
    @task.should_receive(:create_job).and_yield(job)
    @task.create_transcode_job
    job.job_type.should eq 'audio'
    job.original.should eq @task.original 
    job.priority.should eq 4
    job.call_back.should eq nil
    job.retry_delay.should eq 3600
    job.retry_max.should eq 24
    job.tasks.size.should eq 1
  end

end
