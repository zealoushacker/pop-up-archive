class Api::V1::SubscriptionsController < Api::V1::BaseController

  def update
  	plan = SubscriptionPlan.find(params[:subscription][:plan_id])
    current_user.subscribe!(plan, params[:subscription][:offer])
    render status: 200, json: plan
  end

end
