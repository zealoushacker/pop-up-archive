require 'spec_helper'

describe SubscriptionPlan do

  before { StripeMock.start }
  after { StripeMock.stop }

  before do
    @stripe_plan = SubscriptionPlan.create name: 'Test Plan', amount: 10000, hours: 200
    SubscriptionPlan.create name: "*test grandfathered", amount: 100, hours: 1
  end

  let (:plan) { SubscriptionPlan.all.first }

  let (:stripe_plan) { @stripe_plan }

  it 'can fetch all plans from the server' do
    SubscriptionPlan.all.size.should eq 2
  end

  it 'wraps all query results in a local object' do
    plan.should be_a SubscriptionPlan
  end

  it 'gets the name from the stripe object' do
    plan.name.should eq stripe_plan.name
  end

  it 'gets the hours from the stripe ID (first number, separated by _ or -)' do
    plan.hours.should eq 200
  end

  it 'defaults to 2 hours as a minimum' do
    plan = SubscriptionPlan.new(Stripe::Plan.create(name: 'Test Again Plan', amount: 0, id: 'malformed'))
    plan.hours.should eq 2
  end

  it 'gets the dollar amount from the stripe object' do
    plan.amount.should eq 10000
  end

  it 'is marshallable' do
    Marshal.dump(plan)
  end

  it 'can query for ungrandfathered plans without a * at the start of the name' do
    SubscriptionPlan.ungrandfathered.size.should eq 1
  end
end
