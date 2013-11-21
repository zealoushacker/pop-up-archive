class Users::RegistrationsController < Devise::RegistrationsController

  before_filter :update_sign_up_filter

  def create
    build_resource(sign_up_params)

    if resource.save
      yield resource if block_given?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      if existing_user = User.find_by_email(resource.email)
        message = ["Sorry, another account with that email address exists.<br />You can use a different email or"]
        if existing_user.provider.present?
          message << "try logging in with #{existing_user.provider.titleize}."
        else
          message << "reset your password below."
        end
        resource.email = nil
        resource.name = nil
      else
        message = ["There was a problem saving your account. Please fix the errors below."]
      end
      flash[:notice] = message.join(' ')
      clean_up_passwords resource
      respond_with resource
    end
  end

  protected

  def build_resource(*args)
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
      if session[:plan_id].present?
        plan_id = session.delete(:plan_id)
        user.subscribe!(SubscriptionPlan.find(plan_id))
      end
    end
  end
end
