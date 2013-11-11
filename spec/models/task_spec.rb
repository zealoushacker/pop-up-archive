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

