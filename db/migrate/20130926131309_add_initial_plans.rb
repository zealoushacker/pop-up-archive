class AddInitialPlans < ActiveRecord::Migration
  def up
    # SubscriptionPlan.create(hours: 100, amount: 1200, name: 'Small')
    # SubscriptionPlan.create(hours: 250, amount: 2500, name: 'Medium')
    # SubscriptionPlan.create(hours: 500, amount: 5000, name: 'Large')
  end

  def down
    # SubscriptionPlan.find_each {|x| x.destroy }
  end
end
