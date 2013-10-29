require 'spec_helper'

describe User do

  let(:user) { FactoryGirl.create :user }
  before { StripeMock.start }
  after { StripeMock.stop }


  it 'gets a holding collection automatically' do
    user.uploads_collection.should_not be_nil
  end

  context 'payment' do
    let (:plan) { free_plan }
    let (:free_plan) { FactoryGirl.create :subscription_plan, pop_up_hours: 80, amount: 0 }
    let (:paid_plan) { FactoryGirl.create :subscription_plan, pop_up_hours: 80, amount: 2000 }

    it 'has a #customer method that returns a Stripe::Customer' do
      user.customer.should be_a Stripe::Customer
    end

    it 'persists the customer' do
      user.customer.id.should eq User.find(user.id).customer.id
    end

    it 'has the community plan if it is not subscribed' do
      user.plan.should eq SubscriptionPlan.community
    end

    it 'returns the name of the plan' do
      user.plan_name.should eq 'community'
    end

    it 'can have a card added' do
      user.update_card!('void_card_token')
    end

    it 'can be subscribed to a plan' do
      user.subscribe! plan
      user.plan.should eq plan
    end

    it 'wont subscribe to a paid plan when there is no card present' do
      expect { user.subscribe!(paid_plan) }.to raise_error Stripe::InvalidRequestError
    end

    it 'subscribes to paid plans successfully when there is a card present' do
      user.update_card!('void_card_token')
      user.subscribe!(paid_plan)

      user.plan.should eq paid_plan
    end

    it 'has a number of pop up hours determined by the subscription' do
      user.subscribe!(plan)

      user.pop_up_hours.should eq plan.pop_up_hours
    end

    it 'has community plan number of hours when there is no subscription' do
      user.pop_up_hours.should eq SubscriptionPlan::COMMUNITY_PLAN_HOURS
    end

    it 'updates amount of available hours when the plan is updated' do
      user.subscribe!(plan)

      plan.pop_up_hours = 21212121
      plan.save

      user.pop_up_hours.should eq 21212121
    end
  end

  context '#uploads_collection' do
    it 'is a collection' do
      user.uploads_collection.should be_a Collection
    end

    it 'returns the same collection across multiple calls' do
      user.uploads_collection.should eq user.uploads_collection
    end

    it 'is persisted in the database' do
      user.uploads_collection.should be_persisted
    end

    it 'works when the user is not saved' do
      user = FactoryGirl.build :user
      user.uploads_collection.should eq user.uploads_collection
    end

    it 'saves with the user' do
      user = FactoryGirl.build :user
      collection = user.uploads_collection

      user.save.should be true

      user.should be_persisted
      collection.should be_persisted
      user.uploads_collection.should eq collection
      user.uploads_collection.creator.should eq user
    end

    it 'persists as the uploads collection' do
      user = FactoryGirl.build :user
      collection = user.uploads_collection

      user.save

      User.find(user.id).uploads_collection.should eq collection
    end

    it 'handles situations where uploads collection is not there for some reason' do
      user = FactoryGirl.create :user
      user.uploads_collection.destroy
      user.reload

      collection = user.uploads_collection

      user.uploads_collection.should eq collection
      User.find(user.id).uploads_collection.should eq collection
    end
  end

  context "in an organization" do
    it "allows org admin to order transcript" do
      audio_file = AudioFile.new

      ability = Ability.new(user)
      ability.should_not be_can(:order_transcript, audio_file)

      user.organization = FactoryGirl.create :organization

      ability = Ability.new(user)
      ability.should_not be_can(:order_transcript, audio_file)

      user.add_role :admin, user.organization

      ability = Ability.new(user)
      ability.should be_can(:order_transcript, audio_file)
    end

    it 'gets upload collection from the organization' do
      user = FactoryGirl.create :organization_user
      user.organization.run_callbacks(:commit)
      user.uploads_collection.should eq user.organization.uploads_collection
    end

    it "gets list of collections from the organization" do
      user = FactoryGirl.create :organization_user
      organization = user.organization
      organization.run_callbacks(:commit)
      organization.collections.count.should eq 1
      organization.collections << FactoryGirl.create(:collection)
      organization.collections.count.should eq 2
      user.collections.should eq organization.collections
      user.collection_ids.should eq organization.collections.collect(&:id)
    end

    it "returns a role" do
      user.role.should eq :admin

      user.organization = FactoryGirl.create :organization
      user.role.should eq :member

      user.add_role :admin, user.organization
      user.role.should eq :admin
    end

  end

end
