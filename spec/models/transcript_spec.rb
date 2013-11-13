require 'spec_helper'

describe Transcript do

  before(:all) do
    @transcript = FactoryGirl.create :transcript
  end

  it "should get the timed text children" do
    @transcript.timed_texts.size.should eq 2
  end

  it 'should set the confidence' do
    @transcript.confidence.should be_nil
    @transcript.set_confidence
    @transcript.confidence.to_f.should eq 0.8
  end

  it 'should serialize to json with sections' do
    @transcript.as_json.keys.sort.should eq [:sections]
  end

  # it 'should serialize doc to srt format' do
  #   @transcript.to_doc(:srt).should eq "1\n00:00:00,000 --> 00:00:04,000\nthis is some transcript text\n\r\n2\n00:00:05,000 --> 00:00:09,000\nthis is some transcript text\n"
  # end

  it 'should serialize to srt format doc' do
    @transcript.to_srt.should eq "1\n00:00:00,000 --> 00:00:04,999\nthis is some transcript text\n\r\n2\n00:00:05,000 --> 00:00:09,000\nthis is some transcript text\n"
  end

end
