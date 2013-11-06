require 'spec_helper'
require 'ostruct'

describe User do

  let(:user) { FactoryGirl.create :user }
  before { StripeMock.start }
  after { StripeMock.stop }


  it 'gets a holding collection automatically' do
    user.uploads_collection.should_not be_nil
  end

  context 'oauth' do

    it 'applies oauth info' do
      auth = OpenStruct.new(provider: 'foo', uid: 'bar', info: OpenStruct.new(name: 'test', email: 'test@popuparchive.org'))
      user.apply_oauth(auth)
      user.email.should eq 'test@popuparchive.org'
    end
  end

  context 'storage' do
    it 'meters storage' do
      user.used_metered_storage.should eq 0
      user.used_unmetered_storage.should eq 0
    end

    context 'reports' do
      let(:user_slightly_over) { FactoryGirl.create :user, pop_up_hours_cache: 2, used_metered_storage_cache: 2.hours + 30.minutes }
      let(:user_very_over) { FactoryGirl.create :user, pop_up_hours_cache: 2, used_metered_storage_cache: 31.hours }
      let(:user_not_over) { FactoryGirl.create :user, pop_up_hours_cache: 2, used_metered_storage_cache: 1.hours + 21.minutes }

      it 'gets over limit users using cached calculations' do
        User.over_limits.should include(user_slightly_over)
        User.over_limits.should include(user_very_over)
      end

      it 'orders from most to least egregious' do
        user_very_over; user_slightly_over
        User.over_limits.first.should eq user_very_over
        User.over_limits.second.should eq user_slightly_over
      end

      it 'does not include users who have not crossed their limit' do
        User.over_limits.should_not include(user_not_over)
      end

      it 'generates the cache values for a given user' do
        user.stub(pop_up_hours: 25, used_metered_storage: 21.hours)

        user.save

        user.used_metered_storage_cache.should eq nil
        user.pop_up_hours_cache.should eq nil

        user.update_usage_report!

        user_again = User.find(user.id)

        user_again.used_metered_storage_cache.should eq 21.hours
        user_again.pop_up_hours_cache.should eq 25
      end
    end
  end

  context 'payment' do
    let (:plan) { free_plan }
    let (:free_plan) { FactoryGirl.create :subscription_plan, pop_up_hours: 80, amount: 0 }
    let (:paid_plan) { FactoryGirl.create :subscription_plan, pop_up_hours: 80, amount: 2000 }

    it 'has an amount' do
      user.plan_amount.should eq 0
    end

    it 'has a #customer method that returns a Stripe::Customer' do
      user.customer.should be_a Stripe::Customer
    end

    it 'persists the customer' do
      user.customer.id.should eq User.find(user.id).customer.id
    end

    it 'deletes the customer' do
      user.customer.should_receive(:delete).and_return(true)
      user.send(:delete_customer)
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

    it 'can get current card if there is one' do
      user.active_credit_card.should be_nil
      user.update_card!('void_card_token')
      user.active_credit_card.should_not be_nil
    end

    it 'can get current card json ' do
      user.update_card!('void_card_token')
      cc = {"last4"=>"4242", "type"=>"Visa", "exp_month"=>4, "exp_year"=>2016}
      user.active_credit_card_json['type'].should eq 'Visa'
      user.active_credit_card_json.keys.sort.should eq ["exp_month", "exp_year", "last4", "type"]
    end

    it 'can be subscribed to a plan' do
      user.subscribe! plan
      user.plan.should eq plan
    end

    it 'won\'t subscribe to a paid plan when there is no card present' do
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

    it 'is not listed as searchable' do
      user.searchable_collection_ids.should_not be_include(user.uploads_collection.id)
    end
  end

  context "in an organization" do

    it "can be added to an organization" do
      user.organization.should be_nil
      user.should_not be_in_organization
      user.organization = FactoryGirl.create :organization
      user.should be_in_organization
    end

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
