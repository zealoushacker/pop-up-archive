require 'spec_helper'

describe Task do
  before { StripeMock.start }
  after { StripeMock.stop }
  
  it "should allow writing to the extras attributes" do
    task = FactoryGirl.build :task
    task.extras = {test: 'test value'}
    task.save
  end

  it 'should persist the extras attributes' do
    task = FactoryGirl.create :task
    task.extras = {test: 'test value'}
    task.save

    Task.find(task.id).extras['test'].should eq 'test value'
  end

  it 'should persist the owner.storage.id' do
    task = FactoryGirl.create :task
    task.storage_id.should eq task.owner.storage.id
  end

  it 'should return type_name' do
    task = FactoryGirl.create :task
    task.type_name.should eq 'task'

    class Tasks::GoodTestTask < Task; end;
    Tasks::GoodTestTask.new.type_name.should eq 'good_test'
  end

  it 'should get the original from the owner' do
    task = FactoryGirl.create :task
    task.original.should eq task.owner.process_file_url
  end

  describe 'fixer call backs' do
    before {
      @task = FactoryGirl.build :task
      @task.extras[:call_back_url] = 'https://www.popuparchive.com/test'
      @task.save!
      @task.reload
    }

    it "should default a call_back_token" do
      @task.extras['cbt'].should_not be_nil
      @task.call_back_token.should eq @task.extras['cbt']
    end

    it 'should get the call_back_url from extras' do
      @task.call_back_url.should eq "https://www.popuparchive.com/test?cbt=#{@task.extras['cbt']}"
    end

    it 'should get the call_back_url from owner' do
      @task.extras.delete('call_back_url')
      @task.call_back_url.should end_with(".popuparchive.com/fixer_callback/files/audio_file/#{@task.owner.id}?cbt=#{@task.extras['cbt']}")
    end

    # it "should not update from fixer without call_back_token" do
    #   params = {"call_back"=>"https://www.popuparchive.com/api/items/6841/audio_files/9503", "id"=>171851, "label"=>@task.id.to_s, "options"=>nil, "result"=>nil, "task_type"=>"analyze", "result_details"=>{"status"=>"complete", "message"=>"analysis complete", "info"=>{"size"=>517115014, "content_type"=>"audio/vnd.wave", "channel_mode"=>"Mono", "bit_rate"=>705, "length"=>5862, "sample_rate"=>44100}, "logged_at"=>"2013-11-11T15:34:21Z"}, "job"=>{"id"=>151217, "job_type"=>"audio", "original"=>"s3://production.popuparchive.prx.org/jack110413-lees4interview-wav.rzFZWG.popuparchive.org/JACK110413_Lees4interview.WAV", "status"=>"created"}}
    #   @task.update_from_fixer(params).should be_false
    #   @task.results.should_not eq params["result_details"]
    # end

    it "should update from fixer with call_back_token" do
      params = {"cbt" => @task.call_back_token, "call_back"=>"https://www.popuparchive.org/api/items/6841/audio_files/9503", "id"=>171851, "label"=>@task.id.to_s, "options"=>nil, "result"=>nil, "task_type"=>"analyze", "result_details"=>{"status"=>"complete", "message"=>"analysis complete", "info"=>{"size"=>517115014, "content_type"=>"audio/vnd.wave", "channel_mode"=>"Mono", "bit_rate"=>705, "length"=>5862, "sample_rate"=>44100}, "logged_at"=>"2013-11-11T15:34:21Z"}, "job"=>{"id"=>151217, "job_type"=>"audio", "original"=>"s3://production.popuparchive.prx.org/jack110413-lees4interview-wav.rzFZWG.popuparchive.org/JACK110413_Lees4interview.WAV", "status"=>"created"}}
      @task.update_from_fixer(params).should be_true
      @task.results.should eq params["result_details"]
    end

  end

  describe "manage results" do

    before {
      @task = FactoryGirl.create :task
      @task.results = {"status"=>"complete", "message"=>"analysis complete", "info"=>{"services"=>["open_calais", "yahoo_content_analysis"], "stats"=>{"topics"=>0, "tags"=>0, "entities"=>7, "relations"=>0, "locations"=>2}}, "logged_at"=>"2013-11-11T15:38:19Z"}
      @task.save!
      @task.reload
    }

    it 'should save results' do
      @task.results.keys.sort.should eq ["info", "logged_at", "message", "status"]
      @task.results[:status].should eq "complete"
    end

    it 'should be able to access results as indifferent access' do
      @task.results[:info][:stats][:locations].should eq 2
      @task.results['info']['stats']['locations'].should eq 2
    end

  end
 

end

