require 'spec_helper'
describe Api::V1::AudioFilesController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  login_user

  before :each do
    request.accept = "application/json"
  end

  describe "create" do

    before :each do
      @audio_file = FactoryGirl.build :audio_file, duration: 90
    end

    it 'create' do
      post 'create', :item_id => @audio_file.item.id, :title => ''
      response.should be_success
    end

  end

  describe "show and update existing" do

    before :each do
      @audio_file = FactoryGirl.create :audio_file, duration: 90
    end

    it 'show' do
      get 'show', :id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_redirect
    end

    it 'update' do
      put 'update', :id => @audio_file.id, :item_id => @audio_file.item.id, :title => 'new title'
      response.should be_success
    end

    it 'update from fixer' do
      put 'update', id: @audio_file.id, item_id: @audio_file.item.id, task: {label: @audio_file.id, result_details: {status: 'created'}, job: {id: 123 }}
      response.should be_success
    end

    it 'transcript_text' do
      get 'transcript_text', :audio_file_id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
    end

    it 'upload_to' do
      get 'upload_to', :audio_file_id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
    end

    it 'destroy' do
      delete 'destroy', :id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
    end

  end

  describe "upload callbacks" do

    before :each do
      @audio_file = FactoryGirl.create :audio_file, duration: 90

      @options = {
        user_id:       @logged_in_user.id,
        filename:      'test.mp3',
        filesize:      1000,
        last_modified: "2013-11-17 00:59:21 UTC"
      }
      @identifier = Tasks::UploadTask.make_identifier(@options)

      @audio_file.tasks << Tasks::UploadTask.new(identifier: @identifier)
    end

    it 'init_signature' do
      get 'init_signature', audio_file_id: @audio_file.id, item_id: @audio_file.item.id,
        key:           'test.mp3',
        filename:      'test.mp3',
        filesize:      1000,
        last_modified: 1.hour.ago
      response.should be_success
    end

    it 'all_signatures' do
      get 'all_signatures', @options.merge( audio_file_id: @audio_file.id, item_id: @audio_file.item.id,
        key:           'test.mp3',
        num_chunks:    1,
        upload_id:     'thisisnotanuploadid')
      response.should be_success
    end

    it 'chunk_loaded' do
      get 'chunk_loaded', @options.merge(audio_file_id: @audio_file.id, item_id: @audio_file.item.id, chunk: 1)
      response.should be_success
    end

    it 'upload_finished' do
      get 'upload_finished', @options.merge(audio_file_id: @audio_file.id, item_id: @audio_file.item.id)
      response.should be_success
    end

  end

  describe "admin only" do

    before(:each) {
      @audio_file = FactoryGirl.create :audio_file, duration: 90
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @current_user = FactoryGirl.create(:organization_user)
      @current_user.add_role :admin, @current_user.organization

      sign_in @current_user
    }

    it "adds to amara" do
      # User.any_instance.stub(:card).and_return(true)
      post 'add_to_amara', :audio_file_id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
      response.should render_template "add_to_amara"
    end


    it "returns http success with valid attributes" do
      # User.any_instance.stub(:card).and_return(true)
      post 'order_transcript', :audio_file_id => @audio_file.id, :item_id => @audio_file.item.id
      response.should be_success
      response.should render_template "order_transcript"
    end

  end


end
