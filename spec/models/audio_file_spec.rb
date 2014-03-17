require 'spec_helper'

describe AudioFile do

  before {
    SubscriptionPlan.reset_cache
    StripeMock.start
  }
  after { StripeMock.stop }

  context "basics" do

    before(:each) {
      @audio_file = FactoryGirl.create :audio_file
    }

    it "should provide filename" do
      @audio_file.filename.should eq 'test.mp3'
      @audio_file.filename('ogg').should eq 'test.ogg'
    end

    it "should provide filename for remote url" do
      audio_file = AudioFile.new
      audio_file.item = @audio_file.item
      audio_file.user = @audio_file.user

      audio_file.remote_file_url = "http://www.prx.org/test.wav"
      audio_file.filename.should eq 'test.wav'
      audio_file.filename('ogg').should eq 'test.ogg'

      audio_file.remote_file_url = "http://www.prx.org/test"
      audio_file.filename.should eq 'test'
      audio_file.filename('ogg').should eq 'test.ogg'
      audio_file.filename(nil).should eq 'test'
    end

    it "should provide a url" do
      @audio_file.url.should eq '/test.mp3'
    end

    it "should provide a url for a version" do
      @audio_file.url(:ogg).should eq '/test.ogg'
    end

    it "should provide a list of urls when transcoded" do
      @audio_file.transcoded_at = Time.now
      @audio_file.urls.sort.should eq [@audio_file.url(:mp3), @audio_file.url(:ogg)]
    end

    it "should provide original url for urls when not transcoded" do
      @audio_file.urls.should eq [@audio_file.url]
    end

    it "should provide url for private file" do
      audio_file = FactoryGirl.create :audio_file_private
      audio_file.url(nil).should end_with('.popuparchive.org/test.mp3')
      audio_file.url.should end_with('.popuparchive.org/test.mp3')
      audio_file.url(:ogg).should end_with('.popuparchive.org/test.ogg')
    end

  end

  context "transcoding" do

    it 'should have a nil file' do
      audio_file = AudioFile.new
      audio_file.file.path.should be_blank

      audio_file = FactoryGirl.create :audio_file_private
      audio_file.file.path.should_not be_blank
    end

    it 'should  have a process url' do
      audio_file = FactoryGirl.create :audio_file_private
      audio_file.file.should_not be_nil
      audio_file.file.fog_credentials[:provider].downcase.should eq 'aws'
      audio_file.destination.should_not be_nil
      audio_file.destination.should end_with('.popuparchive.org/test.mp3')

      audio_file.process_file_url.should_not be_nil
      audio_file.process_file_url.should end_with('.popuparchive.org/test.mp3')
    end

    it "should use the version label as the extension" do
      audio_file = FactoryGirl.create :audio_file
      File.basename(audio_file.file.mp3.url).should eq "test.mp3"
      File.basename(audio_file.file.ogg.url).should eq "test.ogg"
    end

    it "should know versions to look for" do
      AudioFileUploader.version_formats.keys.sort.should eq ['mp3', 'ogg']
    end

    it "should create detect task" do
      audio_file = FactoryGirl.create :audio_file
      audio_file.storage.should be_automatic_transcode
      audio_file.transcode_audio
      audio_file.tasks.last.class.should == Tasks::DetectDerivativesTask
    end

    it "should create transcode task" do
      audio_file = FactoryGirl.create :audio_file_private
      audio_file.storage.should_not be_automatic_transcode
      audio_file.transcode_audio
      audio_file.tasks.last.class.should == Tasks::TranscodeTask
    end

    it "should check transcode complete" do
      audio_file = FactoryGirl.create :audio_file_private
      audio_file.should_not be_is_transcode_complete
    end

  end

  context "copy and move collections" do

    it "should not create a copy task for current storage id" do

      audio_file = FactoryGirl.build :audio_file

      audio_file.storage.id.should eq(audio_file.item.storage.id)
      audio_file.copy_to_item_storage.should == false

      audio_file.storage_configuration = FactoryGirl.build :storage_configuration_popup

      a_sid = audio_file.storage.id
      i_sid = audio_file.item.storage.id
      a_sid.should_not eq(i_sid)
      audio_file.copy_to_item_storage.should == true
    end

    it "should handle a remote url with query string" do
      audio_file = AudioFile.new
      audio_file.remote_file_url = "http://www.prx.org/test?query=string"
      audio_file.storage_configuration = FactoryGirl.build :storage_configuration_archive
      audio_file.destination_path.should == '/test'
    end

    it "should use s3 for private item in copy_media=true collection" do
      audio_file = FactoryGirl.create :audio_file_private
      audio_file.process_file_url.should match("s3://(.*)/untitled.(.*).popuparchive.org/test.mp3")
    end

    it "should use http for public item in copy_media=true collection" do
      audio_file = FactoryGirl.create :audio_file
      audio_file.process_file_url.should eq '/test.mp3'
    end

    it "should use original url for item in copy_media=false collection" do
      audio_file = FactoryGirl.build :audio_file_no_copy_media
      audio_file.remote_file_url = "http://www.prx.org/test.wav"
      audio_file.save
      audio_file.process_file_url.should eq "http://www.prx.org/test.wav"
    end

  end

  context "transcripts" do

    before(:each) {
      @audio_file = FactoryGirl.build :audio_file_private
    }

    it 'should order only start of transcript for free private audio' do
      @audio_file.user.plan.should eq SubscriptionPlan.community
      @audio_file.should_receive(:start_transcribe_job)
      @audio_file.transcribe_audio
    end

    it 'should order start and all transcripts for internet archive audio' do
      @audio_file = FactoryGirl.build :audio_file
      @audio_file.user.plan.should eq SubscriptionPlan.community
      @audio_file.should_receive(:start_transcribe_job)
      @audio_file.should_receive(:start_transcribe_job)
      @audio_file.transcribe_audio
    end

    it 'should order start and all transcripts for organizations' do
      @audio_file.user.organization = FactoryGirl.build :organization
      @audio_file.should_receive(:start_transcribe_job).twice
      @audio_file.transcribe_audio
    end

    it "should return transcript for legacy transcript text" do
      @audio_file.transcript = '[{"start_time":0,"end_time":9,"text":"one","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"two","confidence":0.8770266}]'
      @audio_file.transcript_text.should_not be_blank
      @audio_file.transcript_text.should eq "one\ntwo"
      @audio_file.transcript_array.count.should == 2
    end

    it "should return transcript for timed transcript instead of legacy" do
      json = '[{"start_time":0,"end_time":9,"text":"three","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"four","confidence":0.8770266},{"start_time":16,"end_time":25,"text":"five","confidence":0.8770266}]'
      @audio_file.transcript = '[{"start_time":0,"end_time":9,"text":"one","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"two","confidence":0.8770266}]'

      trans = @audio_file.transcripts.build(language: 'en-US', identifier: "identifier", start_time: 0, end_time: 25)
      trans_json = JSON.parse(json)
      trans_json.each do |row|
        tt = trans.timed_texts.build({
          start_time: row['start_time'],
          end_time:   row['end_time'],
          confidence: row['confidence'],
          text:       row['text']
        })
      end

      @audio_file.transcript_text.should_not be_blank
      @audio_file.transcript_text.should eq "three\nfour\nfive"
      @audio_file.transcript_array.count.should == 3
      @audio_file.transcript_array.collect{|t|t['text']}.join("\n").should eq "three\nfour\nfive"
    end

  end

  describe "#update_from_fixer" do

    before(:each) {
      @audio_file = FactoryGirl.create :audio_file
    }

    it 'generate callback for fixer' do
      @audio_file.call_back_url.should end_with(".popuparchive.org/fixer_callback/files/audio_file/#{@audio_file.id}")
    end

    it 'updates job id and results' do
      task = @audio_file.analyze_audio
      fixer_result = {"call_back"=>"https://www.popuparchive.org/api/items/6841/audio_files/9503", "id"=>171851, "label"=>task.id.to_s, "options"=>nil, "result"=>nil, "task_type"=>"analyze", "result_details"=>{"status"=>"complete", "message"=>"analysis complete", "info"=>{"size"=>517115014, "content_type"=>"audio/vnd.wave", "channel_mode"=>"Mono", "bit_rate"=>705, "length"=>5862, "sample_rate"=>44100}, "logged_at"=>"2013-11-11T15:34:21Z"}, "job"=>{"id"=>151217, "job_type"=>"audio", "original"=>"s3://production.popuparchive.prx.org/jack110413-lees4interview-wav.rzFZWG.popuparchive.org/JACK110413_Lees4interview.WAV", "status"=>"created"}}
      @audio_file.update_from_fixer(fixer_result)
      task.reload
      task.extras['job_id'].should eq "151217"
      task.results.should eq fixer_result['result_details']
    end

  end


  describe '#metered?' do
    let(:popup_storage) { StorageConfiguration.popup_storage.tap(&:save) }
    let(:archive_storage) { StorageConfiguration.archive_storage.tap(&:save) }
    it 'is true when using the application s3 bucket for storage' do
      audio_file = FactoryGirl.build :audio_file, storage_configuration: popup_storage
      audio_file.should be_metered
    end
    it 'is false when using public storage' do
      audio_file = FactoryGirl.build :audio_file, storage_configuration: archive_storage
      audio_file.should_not be_metered
    end
    it 'is persisted' do
      unmetered = FactoryGirl.create :audio_file, storage_configuration: archive_storage
      metered   = FactoryGirl.create :audio_file, storage_configuration: popup_storage
      AudioFile.where(metered: true).should include(metered)
      AudioFile.where(metered: false).should include(unmetered)
      AudioFile.where(metered: true).should_not include(unmetered)
      AudioFile.where(metered: false).should_not include(metered)
    end
    it 'does not call is_metered? when pulled from the database' do
      unmetered = FactoryGirl.create :audio_file, storage_configuration: archive_storage
      def unmetered.is_metered?
        true
      end
      unmetered.metered?.should be false
    end
  end

end
