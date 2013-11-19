require 'spec_helper'

describe CsvImportWorker do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "processes a url" do
    @import = FactoryGirl.create :csv_import
    @worker = CsvImportWorker.new
    @worker.perform(@import.id).should eq true
  end

end
