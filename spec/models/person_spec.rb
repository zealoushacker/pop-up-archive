require 'spec_helper'

describe Person do
  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) {
    @person = FactoryGirl.create :person
    @person.items(true)
  }
  
  it "can have contributions and items" do
    @person.contributions.count.should eq 1
    @person.items.count.should eq 1
  end

  it "has an uploads collection" do
    @person.items.first.should_receive(:update_index_async)
    @person.name = 'change'
    @person.save!
  end

end
