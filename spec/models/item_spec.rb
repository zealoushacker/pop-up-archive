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

  it "should change visibility when collection changes" do    
    item = FactoryGirl.create :item
    item.set_defaults
    item.is_public.should == true
    collection = FactoryGirl.create :collection_private
    item.collection_id = collection.id
    item.collection = collection
    item.save!
    item.is_public.should == false
  end

end
