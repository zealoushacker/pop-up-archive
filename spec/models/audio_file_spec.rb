require 'spec_helper'

describe AudioFile do
  before { StripeMock.start }
  after { StripeMock.stop }

  context "basics" do
    it "should provide a url" do
      audio_file = FactoryGirl.create :audio_file
      audio_file.url.should eq '/test.mp3'
    end

    it "should provide a url for a version" do
      audio_file = FactoryGirl.create :audio_file
      audio_file.url(:ogg).should eq '/test.ogg'
    end

    it "should provide a list of urls when transcoded" do
      audio_file = FactoryGirl.create :audio_file
      audio_file.transcoded_at = Time.now
      audio_file.urls.sort.should eq [audio_file.url(:mp3), audio_file.url(:ogg)]
    end

    it "should provide original url for urls when not transcoded" do
      audio_file = FactoryGirl.create :audio_file
      audio_file.urls.should eq [audio_file.url]
    end

    it "should provide url for private file" do
      audio_file = FactoryGirl.create :audio_file_private
      audio_file.url(nil).should end_with('.popuparchive.org/test.mp3')
      audio_file.url.should end_with('.popuparchive.org/test.mp3')
      audio_file.url(:ogg).should end_with('.popuparchive.org/test.ogg')
    end

  end

  context "transcoding" do

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

  end

  context "transcripts" do

    it "should return transcript for legacy transcript text" do
      audio_file = FactoryGirl.build :audio_file
      audio_file.transcript = '[{"start_time":0,"end_time":9,"text":"one","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"two","confidence":0.8770266}]'
      audio_file.transcript_text.should_not be_blank
      audio_file.transcript_text.should eq "one\ntwo"
      audio_file.transcript_array.count.should == 2
    end

    it "should return transcript for timed transcript instead of legacy" do
      json = '[{"start_time":0,"end_time":9,"text":"three","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"four","confidence":0.8770266},{"start_time":16,"end_time":25,"text":"five","confidence":0.8770266}]'
      audio_file = FactoryGirl.build :audio_file
      audio_file.transcript = '[{"start_time":0,"end_time":9,"text":"one","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"two","confidence":0.8770266}]'
      trans = audio_file.process_transcript(json)
      audio_file.transcript_text.should_not be_blank
      audio_file.transcript_text.should eq "three\nfour\nfive"
      audio_file.transcript_array.count.should == 3
      audio_file.transcript_array.collect{|t|t['text']}.join("\n").should eq "three\nfour\nfive"
    end

    it "should process creating a transcript from JSON" do
      json = '[{"start_time":0,"end_time":9,"text":"from Wednesday January 30th 2013 the following is a replay of the radio doctor daily session in North Carolina House of Representatives","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"tractor seat visitors","confidence":0.8770266}]'
      audio_file = FactoryGirl.build :audio_file
      transcript = audio_file.process_transcript(json)
      transcript.timed_texts.count.should == 2
    end

    it "should process creating a transcript from JSON and calculate confidence" do
      json = '[{"start_time":0,"end_time":9,"text":"from Wednesday January 30th 2013 the following is a replay of the radio doctor daily session in North Carolina House of Representatives","confidence":1.0},{"start_time":8,"end_time":17,"text":"tractor seat visitors","confidence":0.0}]'
      audio_file = FactoryGirl.build :audio_file
      transcript = audio_file.process_transcript(json)
      transcript.confidence.should eq 0.5
      transcript.set_confidence.should eq 0.5
      transcript.confidence.should eq 0.5
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
