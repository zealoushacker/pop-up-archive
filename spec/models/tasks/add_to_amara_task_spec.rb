require 'spec_helper'

describe Tasks::AddToAmaraTask do

  before(:each) do 
    @user = FactoryGirl.create :user
    @audio_file = FactoryGirl.create :audio_file
    @task = Tasks::AddToAmaraTask.new(owner: @audio_file, identifier: 'add_to_amara', extras: { amara_team: 'prx-test-0', user_id: @user.id })
    @task.should_receive(:create_video).and_return(Hashie::Mash.new({id: 'NEWVIDEO'}))
    @task.should_receive(:add_subtitles).and_return(Hashie::Mash.new())
    @task.save!
    @task.run_callbacks(:commit)
  end

  it "should be valid with defaults" do
    task = Tasks::AddToAmaraTask.new(owner: @audio_file, identifier: 'add_to_amara', extras: { amara_team: 'prx-test-0', user_id: @user.id })
    task.should_receive(:create_video).and_return(Hashie::Mash.new({id: 'NEWVIDEO'}))
    task.should_receive(:add_subtitles).and_return(Hashie::Mash.new())
    task.save!
    task.run_callbacks(:commit)

    task.owner.should eq @audio_file
    task.identifier.should eq 'add_to_amara'
    task.team.should eq 'prx-test-0'
    task.should be_valid
  end

  it "should return the video_id" do
    @task.extras['video_id'] = 'RANDOM'
    @task.video_id.should eq 'RANDOM'
  end

  it "should return the user_id" do
    @task.extras['user_id'] = @user.id
    @task.user_id.should eq @user.id
  end

  it "should return the user" do
    @task.extras['user_id'] = @user.id
    @task.user.should eq @user
  end

  it "should have an edit transcript url" do
    @task.extras['video_id'] = 'RANDOM'
    @task.edit_transcript_url.should start_with "http://#{ENV['AMARA_HOST']}/en/onsite_widget/?config=%7B%22videoID%22:%22RANDOM%22,%22videoURL%22:%22http://test.popuparchive.org/media"
    @task.edit_transcript_url.should end_with "/test.ogg%22,%22languageCode%22:%22en%22%7D"
  end

  it "should have audio_file owner" do
    @task.owner.should_not be_nil
    @task.owner.should eq @task.audio_file
  end

  it "should set create_video_options" do
    @task.create_video_options.should_not be_nil
    @task.create_video_options.keys.sort.should eq [:primary_audio_language_code, :team, :title, :video_url]
    @task.create_video_options[:primary_audio_language_code].should eq 'en'
    @task.create_video_options[:team].should eq 'prx-test-0'
    @task.create_video_options[:title].should eq @audio_file.filename
    @task.create_video_options[:video_url].should eq @audio_file.public_url(extension: :ogg)
  end

  it "should order the transcript and add video id to task" do
    task = Tasks::AddToAmaraTask.new(owner: @audio_file, identifier: 'add_to_amara')
    video = Hashie::Mash.new({id: 'NEWVIDEO'})
    task.should_receive(:create_video).and_return(video)
    task.should_receive(:add_subtitles).and_return(Hashie::Mash.new())
    task.order_transcript
    task.video_id.should eq 'NEWVIDEO'
  end

  it "should call amara to create the video" do
    video = Hashie::Mash.new({id: 'NEWVIDEO'})
    response = Hashie::Mash.new({body: video, status: 200})
    amara_response = Amara::Response.new(response)
    task = Tasks::AddToAmaraTask.new(owner: @audio_file, identifier: 'add_to_amara')
    task.amara_client.videos.should_receive(:create).and_return(amara_response)
    task.create_video.should eq video
  end

  it "should parse and save the transcript from amara" do
    subtitles = Hashie::Mash.new(test_subtitles)

    @task.extras['subtitles_version'].to_i.should eq 0

    transcript = @task.load_subtitles(subtitles)

    @task.extras['subtitles_version'].to_i.should eq 4

    transcript.should_not be_nil
    transcript.should be_valid
    transcript.language.should eq 'en-US'
    transcript.identifier.should eq "#{@task.owner.id}_en"
    transcript.start_time.should eq 2
    transcript.end_time.should eq 60
    transcript.confidence.should eq 100

    transcript.timed_texts.count.should eq subtitles.subtitles.count

    tt = transcript.timed_texts.first
    tt.start_time.should eq 2
    tt.end_time.should eq 4
    tt.text.should eq "Call in with your comments"
    tt.confidence.should eq 100
  end

  it "should notify the user" do
    @task.notify_user
    mail = ActionMailer::Base.deliveries.last
    mail.should_not be_nil
  end

  def test_subtitles
    {
      "description"       => "test audio",
      "language"          => {"code"=> "en", "name"=> "English"},
      "metadata"          => {},
      "note"              => "",
      "resource_uri"      => "/api2/partners/videos/5eZU6jdDRfQ2/languages/en/subtitles/",
      "site_url"          => "http://staging.amara.org/videos/5eZU6jdDRfQ2/en/411168/",
      "sub_format"        => "json",
      "title"             => "Hive Mind",
      "version_no"        => 4,
      "version_number"    => 4,
      "video"             => "Hive Mind",
      "video_description" => "test audio",
      "video_title"       => "Hive Mind",
      "subtitles"    => [
        {
          "end"      => 3917,
          "meta"     => {"new_paragraph"=> true},
          "position" => 1,
          "start"    => 2090,
          "text"     => "Call in with your comments"
        },
        {
          "end"      => 9626,
          "meta"     => {"new_paragraph"=> false},
          "position" => 2,
          "start"    => 3917,
          "text"     => "651 227 6000 or 800 242 2828"
        },
        {
          "end"      => 13370,
          "meta"     => {"new_paragraph"=> false},
          "position" => 3,
          "start"    => 9626,
          "text"     => "this is the daily circuit on Minnesota Public Radio News"
        },
        {
          "end"      => 15851,
          "meta"     => {"new_paragraph"=> false},
          "position" => 4,
          "start"    => 13370,
          "text"     => "And I'm Carrie Miller along with Tom Weber"
        },
        {
          "end"      => 17663,
          "meta"     => {"new_paragraph"=> false},
          "position" => 5,
          "start"    => 15851,
          "text"     => "and it is Brain Awareness Week."
        },
        {
          "end"      => 20377,
          "meta"     => {"new_paragraph"=> false},
          "position" => 6,
          "start"    => 17663,
          "text"     => "You've been hearing Tom's segments on ask a neuroscientist"},
        {
          "end"      => 24882,
          "meta"     => {"new_paragraph"=> false},
          "position" => 7,
          "start"    => 20377,
          "text"     => "but this hour we are zeroing in on 3 interesting areas of study"
        },
        {
          "end"      => 29495,
          "meta"     => {"new_paragraph"=> false},
          "position" => 8,
          "start"    => 24882,
          "text"     => "about the brain, and we're calling this the Hive Mind, aren't we Tom?"
        },
        {
          "end"      => 36322,
          "meta"     => {"new_paragraph"=> false},
          "position" => 9,
          "start"    => 29495,
          "text"     => "Well, there's research on how our brains make decisions and it has a tie in to head butting bees."
        },
        {
          "end"      => 37125,
          "meta"     => {"new_paragraph"=> false},
          "position" => 10,
          "start"    => 36322,
          "text"     => "No Way!"
        },
        {
          "end"      => 38317,
          "meta"     => {"new_paragraph"=> false},
          "position" => 11,
          "start"    => 37125,
          "text"     => "They butt heads."
        },
        {
          "end"      => 42018,
          "meta"     => {"new_paragraph"=> false},
          "position" => 12,
          "start"    => 38317,
          "text"     => "Now bees, as you know, they work collectively, and researchers have long wondered"
        },
        {
          "end"      => 46626,
          "meta"     => {"new_paragraph"=> false},
          "position" => 13,
          "start"    => 42018,
          "text"     => "if that collective decision making that bees do has any parallel with the way"
        },
        {
          "end"      => 51357,
          "meta"     => {"new_paragraph"=> false},
          "position" => 14,
          "start"    => 46626,
          "text"     => "that our neurons and our other bits and pieces in our brain run around and help us make decisions."
        },
        {
          "end"      => 54895,
          "meta"     => {"new_paragraph"=> false},
          "position" => 15,
          "start"    => 51357,
          "text"     => "Well now there's research that finds that there's a head butting"
        },
        {
          "end"      => 59489,
          "meta"     => {"new_paragraph"=> false},
          "position" => 16,
          "start"    => 54895,
          "text"     => "that bees do that is key to the process of coming to a consensus."
        },
        {
          "end"      => 60000,
          "meta"     => {"new_paragraph"=> false},
          "position" => 17,
          "start"    => 59489,
          "text"     => "In the hive..."
        }
      ]
    }
  end

end