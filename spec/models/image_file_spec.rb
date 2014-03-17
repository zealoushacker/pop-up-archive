require 'spec_helper'

describe ImageFile do

  context "basics" do

    before(:each) {
      @image_file = FactoryGirl.create :image_file
    }

    it "should have a storage config" do
      @image_file.storage_configuration.should eq nil
    end

    # it "should provide filename" do
    #   @image_file.filename.should eq 'test.jpg'
    # end

    # it "should have a mime_type" do
    #   @image_file.mime_type.should eq 'image'
    # end

  end
end
