require 'spec_helper'

describe ItemResultsPresenter do
  before { StripeMock.start }
  after { StripeMock.stop }

  describe "ItemResultsPresenter" do
    it 'can be created using a result object' do
      @irps = ItemResultsPresenter.new({})
      @irps.should_not be_nil
    end

    it 'creates results ItemResultPresenter per row' do
      @irps = ItemResultsPresenter.new([{},{},{}])
      @irps.results.count.should eq 3
    end

    it 'delegates respond_to?' do
      @irps = ItemResultsPresenter.new([{},{},{}])
      @irps.should be_respond_to(:results)
      @irps.should be_respond_to(:each)
      @irps.should_not be_respond_to(:foobar)
    end

    it 'delegates method_missing' do
      result = [{},{},{}]
      @irps = ItemResultsPresenter.new(result)
      @irps.count.should eq result.count
    end
  end

  describe "ItemResultPresenter" do
    it 'can be created from a single result row' do
      @irp = ItemResultsPresenter::ItemResultPresenter.new({})
      @irp.should_not be_loaded_from_database
    end

    it 'can be created from a single Item object' do
      @item = FactoryGirl.create :item_with_audio
      @irp = ItemResultsPresenter::ItemResultPresenter.new(@item)
      @irp.should_not be_loaded_from_database
      @irp.id.should eq @item.id
      @irp.database_object.should eq @item
      @irp.audio_files.count.should eq 1
    end

  end

end
