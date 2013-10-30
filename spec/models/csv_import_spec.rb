require 'spec_helper'
require 'tasks/transcode_task'

describe CsvImport do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:new_import) { FactoryGirl.build :csv_import }
  let(:import) { FactoryGirl.create :csv_import }

  it "should trigger processing of itself on create" do
    new_import.should_receive(:enqueue_processing)
    new_import.save
  end

  context "state management" do
    it "should start in the new state" do
      new_import.state.should eq "new"
    end

    it "should transition to the queued state on '#enqueue_processing'" do
      new_import.send :enqueue_processing
      new_import.state.should eq "queued_analyze"
    end

    it "should save the state after enqueing processing" do
      new_import.save
      new_import.should_not be_state_index_changed
    end

    it "should transition to the analyzed state after it is analyzed" do
      import.analyze!
      import.state.should eq "analyzed"
    end

    it "should not permit analyzing unless it is saved" do
      expect(-> { new_import.analyze! }).to raise_exception
    end

    it "should not permit analyzing if it is currently analyzing" do
      import.send :state=, "analyzing"
      expect(-> { import.analyze! }).to raise_exception
    end

    it "should enter the analyzing state during analysis" do
      import.should_receive(:state=).with("analyzing").once.and_call_original
      import.should_receive(:state=).with("analyzed").once.and_call_original
      import.analyze!
    end

    it "should transition to the queued_import process on '#enqueue_processing'" do
      import.commit = 'import'
      import.send :enqueue_processing
      import.state.should eq "queued_import"
    end

    it "should transition to the imported state after it is imported" do
      import.commit = 'import'
      import.save

      import.import!
      import.state.should eq "imported"
    end

    it "should enter the importing state during import" do
      import.commit = 'import'
      import.save
      import.should_receive(:state=).with("importing").once.and_call_original
      import.should_receive(:state=).with("imported").once.and_call_original
      import.import!
    end
  end

  context "analysis" do

    let(:headers) do
      headers = nil
      File.open(import.file.path) do |file|
        headers = file.gets.chomp.split(',')
      end
      headers
    end
    
    attr_reader :analyzed_import

    before :all do
      Tasks::TranscodeTask.any_instance.stub(:create_job).and_return(12345)

      @analyzed_import = FactoryGirl.create :csv_import
      @analyzed_import.analyze!
    end

    after :all do
      @analyzed_import.user.collections.destroy
      @analyzed_import.user.destroy
      @analyzed_import.destroy
    end

    it "should start with no rows" do
      import.rows.should be_empty
    end

    it "should create rows records as part of analysis" do
      analyzed_import.rows.should_not be_empty
      analyzed_import.rows.size.should eq %x{wc -l '#{import.file.path}'}.to_i - 1
    end

    it "should start with no headers" do
      import.headers.should_not be_present
    end

    it "should extract headers during analysis" do
      analyzed_import.headers.should eq headers
    end

    it "should create mappings during analysis" do
      analyzed_import.mappings.size.should eq headers.length
    end

    it "should map uncategorizable fields using a standard method" do
      analyzed_import.mappings.first.column.should eq "extra[record_type]"
    end

  end

  context "import" do
  end

  it "should extract the base file name" do
    import.file_name.should eq 'example.csv'
  end

  context "#mappings" do
    let(:nine_mappings) { Array.new(9).map { FactoryGirl.attributes_for :import_mapping }}

    it "should be empty when we start" do
      new_import.mappings.should be_blank
    end

    it "should permit setting a bunch of them" do
      new_import.mappings_attributes = nine_mappings
      new_import.save

      CsvImport.find(new_import.id).mappings.count.should eq 9
    end

    it "should clear out current mappings if they are set again" do
      import.mappings_attributes = nine_mappings
      import.save

      import.mappings_attributes = nine_mappings
      import.save

      import.mappings.count.should eq 9
    end
  end

end
