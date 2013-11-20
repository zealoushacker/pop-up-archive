class Api::V1::PlansController < Api::V1::BaseController
  expose (:subscription_plans) { SubscriptionPlan.ungrandfathered }

  def index
    respond_with subscription_plans
  end
end
