require 'spec_helper'

describe Api::V1::SearchesController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  before :each do
    request.accept = "application/json"
  end

  it 'gets all results' do
    get 'show'
    response.should be_success
    response.should render_template "api/v1/searches/show"
  end

end