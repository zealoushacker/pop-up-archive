require 'spec_helper'

describe Tasks::AnalyzeTask do

  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) do 
    @audio_file = FactoryGirl.create :audio_file
    @task = Tasks::AnalyzeTask.new(owner: @audio_file, identifier: 'analysis')
  end

  it "should create entities from content analysis" do
    analysis = '{"language":"","topics":[{"name":"Business and finance","score":0.952,"original":"Business_Finance"},{"name":"Hospitality and recreation","score":0.937,"original":"Hospitality_Recreation"},{"name":"Law and crime","score":0.868,"original":"Law_Crime"},{"name":"Entertainment and culture","score":0.587,"original":"Entertainment_Culture"},{"name":"Media","score":0.742268,"original":"Media"}],"tags":[{"name":"cashola","score":0.5}],"entities":[],"relations":[],"locations":[]}'
    @task.process_analysis(analysis)
    @audio_file.item.entities.count.should eq 6
  end

  it "should not create dupe entities from content analysis" do
    analysis = '{"language":"","topics":[{"name":"Business and finance","score":0.952,"original":"Business_Finance"},{"name":"Hospitality and recreation","score":0.937,"original":"Hospitality_Recreation"},{"name":"Law and crime","score":0.868,"original":"Law_Crime"},{"name":"Entertainment and culture","score":0.587,"original":"Entertainment_Culture"},{"name":"Media","score":0.742268,"original":"Media"}],"tags":[{"name":"cashola","score":0.5}],"entities":[],"relations":[],"locations":[]}'
    @task.process_analysis(analysis)
    @task.process_analysis(analysis)
    @audio_file.item.entities.count.should eq 6
  end

end
