require 'spec_helper'

describe StorageConfiguration do
  before { StripeMock.start }
  after { StripeMock.stop }

    before(:each) {
      @storage = FactoryGirl.create :storage_configuration    
    }

  it "makes comparisons based on conection info, not id" do
    storage_configuration1 = FactoryGirl.create :storage_configuration
    storage_configuration2 = FactoryGirl.create :storage_configuration
    storage_configuration1.should eq storage_configuration2

    storage_configuration1.bucket = storage_configuration1.bucket + "_test"
    storage_configuration1.should_not eq storage_configuration2
  end

  it 'does not have attributes implemented yet' do
    @storage.provider_attributes.keys.should eq []
  end

  it 'returns credentials suitable for fog/conn use' do
    @storage.credentials.should be_instance_of Hash
    @storage.credentials.keys.sort.should eq [:aws_access_key_id, :aws_secret_access_key, :path_style, :provider]
    @storage.credentials[:provider].should eq 'AWS'
  end

  it 'provides abbr' do
    @storage.abbr_for_provider.should eq 'aws'
  end

  it 'knows if direct upload possible (AWS)' do
    @storage.should be_direct_upload
  end

  it 'knows if audio transcoded automatically (IA)' do
    @storage.should_not be_automatic_transcode
  end

  it 'knows if storage allows folders within buckets' do
    @storage.should be_use_folders
  end

  it 'knows if at amazon' do
    @storage.should be_at_amazon
    StorageConfiguration.archive_storage.should_not be_at_amazon
  end

  it 'knows if at archive' do
    @storage.should_not be_at_internet_archive
    StorageConfiguration.archive_storage.should be_at_internet_archive
  end

  it 'has default providers' do
    StorageConfiguration.archive_storage.should be_at_internet_archive
    StorageConfiguration.popup_storage.should be_at_amazon
  end

end
