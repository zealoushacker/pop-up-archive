class Users::RegistrationsController < Devise::RegistrationsController

  before_filter :update_sign_up_filter

  protected

  def build_resource(*args)
    hash = args[0] || resource_params || {}
    session[:plan_id] = params[:plan_id] if params[:plan_id].present?    
    session[:card_token] = params[:card_token] if params[:card_token].present?
    super
  end

  def update_sign_up_filter
    devise_parameter_sanitizer.for(:sign_up) do |default_params|
      default_params.permit(:name, :password, :password_confirmation, :email, :provider, :uid)
    end
  end

  def sign_up(resource_name, resource)
    set_card_and_plan(resource)
    super
  end

  expose(:plan){ get_plan }
  expose(:card_available?) { get_card_available }

  def get_plan
    if plan_id.present?
      SubscriptionPlan.find(plan_id)
    else
      SubscriptionPlan.community
    end
  end

  def get_card_available
    Rails.logger.debug(session)
    !!session[:card_token]
  end

  def plan_id
    session[:plan_id] = (params[:plan_id] || session[:plan_id])
  end

  def set_card_and_plan(user)
    if session[:card_token].present?
      card_token = session.delete(:card_token)
      user.update_card!(card_token)
    end
    if session[:plan_id].present?
      plan_id = session.delete(:plan_id)
      user.subscribe!(SubscriptionPlan.find(plan_id))
    end
  end
end
