require 'spec_helper'

describe Item do
  before { StripeMock.start }
  after { StripeMock.stop }
  context "#geographic_location" do
    it "should set the geolocation using Geoloation.for_name" do
      Geolocation.should_receive(:for_name).with("Cambridge, MA")
      FactoryGirl.build :item, geographic_location: "Cambridge, MA"
    end

    it "should return the string name of the associated geolocation" do
      record = FactoryGirl.create :item, geographic_location: "Madison, WI"

      record.geographic_location.should eq "Madison, WI"
    end
  end

  it 'has the collection title' do
    item = FactoryGirl.create :item
    item.collection_title.should eq "test collection"

  end

  it "can be deleted" do
    item = FactoryGirl.create :item
    item.should_receive(:remove_from_index).and_return(true)
    item.destroy
  end

  it "public url" do
    item = FactoryGirl.create :item
    item.url.should_not be_nil
    item.url.should eq "http://test.popuparchive.org/collections/#{item.collection_id}/items/#{item.id}"
  end

  it "should allow writing to the extra attributes" do
    item = FactoryGirl.build :item
    item.extra['testkey'] = 'test value'
    item.save
  end

  it 'should persist the extra attributes' do
    item = FactoryGirl.create :item
    item.extra['testKey'] = 'testValue2'
    item.save

    Item.find(item.id).extra['testKey'].should eq 'testValue2'
  end

  it "should create a unique token from the title and keep it" do
    item = FactoryGirl.build :item
    item.title = 'test'
    item.token.should start_with('test.')
    item.token.should end_with('.popuparchive.org')
    item.title = 'test2'
    item.token.should start_with('test.')
  end

  it "should change visibility to false when collection changes" do    
    item = FactoryGirl.create :item
    item.set_defaults
    item.is_public.should == true
    collection = FactoryGirl.create :collection_private
    item.collection_id = collection.id
    item.collection = collection
    item.save!
    item.is_public.should == false
  end

  it "should change visibility to true when collection changes" do    
    item = FactoryGirl.create :item_private
    item.set_defaults
    item.is_public.should == false
    collection = FactoryGirl.create :collection_public
    item.collection_id = collection.id
    item.collection = collection
    item.save!
    item.is_public.should == true
  end

  it 'should have an upload collection' do
    item = FactoryGirl.create :item
    item.upload_to.should eq item.collection.upload_to

    item = FactoryGirl.create :item_private
    item.upload_to.should eq item.storage
  end

  it 'tags_for_index' do
    item = FactoryGirl.create :item
    item.tags = ['x/a', 'y/b', 'x/c']
    item.send(:tags_for_index).should eq ['x', 'x/a', 'x/c', 'y', 'y/b']
  end



end
