require 'spec_helper'
describe Api::V1::AudioFilesController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  before :each do
    request.accept = "application/json"
  end

  describe "POST 'create'" do

    login_user

    before :each do
      @audio_file = FactoryGirl.create :audio_file, duration: 90
    end

    it "returns http success with valid attributes" do
      # User.any_instance.stub(:card).and_return(true)
      post 'add_to_amara', :audio_file_id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
      response.should render_template "add_to_amara"
    end


    it "returns http success with valid attributes" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @current_user = FactoryGirl.create(:organization_user)
      @current_user.add_role :admin, @current_user.organization

      sign_in @current_user

      # User.any_instance.stub(:card).and_return(true)
      post 'order_transcript', :audio_file_id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
      response.should render_template "order_transcript"
    end

  end
end
