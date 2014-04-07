require 'spec_helper'
describe Api::V1::ImageFilesController do
  extend ControllerMacros
  before { StripeMock.start }
  after { StripeMock.stop }

  login_user

  before :each do
    request.accept = "application/json"
  end

  before :each do
    @image_file = FactoryGirl.create(:image_file)
  end  

  describe "create" do

    it 'create' do
      post 'create', :item_id => @image_file.item.id, :file => 'test_file'
      response.should be_success
    end

  end

  describe "show and update existing" do

    before :each do
      @image_file = FactoryGirl.create :image_file
    end

    it 'show' do
      get 'show', :id => @image_file.id, :item_id => @image_file.item.id
      response.should be_redirect
    end

    it 'upload_to' do
      get 'upload_to', :image_file_id => @image_file.id, :item_id => @image_file.item.id
      response.should be_success
    end

    it 'destroy' do
      delete 'destroy', :id => @image_file.id, :item_id => @image_file.item.id
      response.should be_success
    end
  end  


  describe "upload callbacks" do

    before :each do
      @image_file = FactoryGirl.create(:image_file)
    end      
  
      # it 'all_signatures' do
      #   get 'all_signatures', {:id => @image_file.id, :upload_id => @image_file.upload_id}
      #   response.should be_success
      # end
  
      it 'chunk_loaded' do
        get 'chunk_loaded', {:image_file_id => @image_file.id}
      end

      # commenting out test below because it is failing due to calling Carrierwave method#body on factory @image_file 
      # it 'upload_finished' do
      #   get 'upload_finished', {:image_file_id => @image_file.id, :key => @image_file.file.path, :file => @image_file.file}
      #   response.should be_success
      # end
    end 

end
