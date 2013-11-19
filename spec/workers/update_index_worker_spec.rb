require 'spec_helper'

describe UpdateIndexWorker do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "index a model" do
    @item = FactoryGirl.create :item
    @worker = UpdateIndexWorker.new
    Item.should_receive(:find_by_id).and_return(@item)
    @item.should_receive(:update_index).and_return(true)
    @worker.perform(@item.class.name, @item.id).should eq true
  end

end
