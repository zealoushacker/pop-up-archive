require 'spec_helper'

describe Collection do
  before { StripeMock.start }
  after { StripeMock.stop }

  describe "defaults" do

    before(:each) {
      @collection = Collection.new(title: 'test')
    }

    it "should be valid with default attributes" do
      @collection.save.should be_true
    end

    it "should default to aws storage" do
      @collection.set_storage
      @collection.default_storage.provider.should eq 'AWS'
    end

    it "should assign storage configuration based on provider" do
      @collection.storage = 'AWS'
      @collection.default_storage.provider.should eq 'AWS'

      @collection.storage = 'InternetArchive'
      @collection.default_storage.provider.should eq 'InternetArchive'
    end

  end

  it "should set storage" do
    @collection = FactoryGirl.build :collection
    @collection.upload_to.should_not be_nil
    @collection.upload_storage.should be_nil
    @collection.default_storage.should_not be_nil
  end

  it "should set org based on creator" do
    @creator = FactoryGirl.create :organization_user
    @creator.organization.should_not be_nil

    @collection = FactoryGirl.create :collection, creator: @creator
    @collection.run_callbacks(:commit)
    @collection.creator.should eq @creator
    @collection.collection_grants.count.should eq 1
  end

  it "can be for uploads" do
    @creator = FactoryGirl.create :user
    @creator.uploads_collection.should be_uploads_collection
  end

end
