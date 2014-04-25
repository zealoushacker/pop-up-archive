require 'spec_helper'
require Rails.root.join 'app/uploaders/image_uploader.rb'
describe ImageFile do

  context "basics" do

    before(:each) {
      @image_file = FactoryGirl.create :image_file
    }

    it "should have a storage config" do
      @image_file.storage_configuration.should eq nil
    end

    it "should provide filename" do
      @image_file.filename.should eq 'test.jpg'
    end 
    
    it "should have a mime_type" do
      @image_file.mime_type.should eq 'image'
    end       

    it "should save a thumbnail version" do
      ImageFile.any_instance.stub(:save_thumb_version).and_return(true)
      @image_file.file.thumb.should_not be_nil
    end

    it "should know that it is uploaded" do
      ImageFile.any_instance.stub(:file_uploaded).and_return(true)
      @image_file.is_uploaded.should be true
    end

  end
end
