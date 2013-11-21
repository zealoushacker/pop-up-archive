class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def prx
    complete_oauth_login do
      if existing_user = User.find_by_email(@user.email)
        message = ["Sorry, another account with that email address exists.<br />You can use a different email or"]
        if existing_user.provider.present?
          message << "try logging in with #{existing_user.provider.titleize}."
        else
          message << "reset your password below."
        end
        @user = User.new
      else
        message = ["We need some more information to finish setting up your account."]
        session_oauth_data[:should_validate] = true
      end
      message.join(' ')
    end
  end

  alias_method :facebook, :prx

  def twitter
    complete_oauth_login do
      "We need your email address to finish signing you in with Twitter."
    end
  end

  private

  def complete_oauth_login
    finish_profile yield unless oauth_login
  end


  def oauth_login(auth_hash=omniauth)
    @user = User.find_for_oauth(auth_hash, current_user)

    if @user.persisted?
      set_card_and_plan
      sign_in_and_redirect @user, event: :authentication
    else
      return false
    end
  end

  def omniauth
    request.env['omniauth.auth']
  end

  def session_oauth_data
    session['devise.oauth_data'] ||= HashWithIndifferentAccess.new()
  end

  def finish_profile(message=nil, auth_hash=omniauth)
    session_oauth_data[:uid]      = auth_hash.uid
    session_oauth_data[:provider] = auth_hash.provider
    session_oauth_data[:name]     = auth_hash.info.name
    session_oauth_data[:email]    = auth_hash.info.email

    redirect_to new_user_registration_url, notice: message
  end

  def set_card_and_plan
    if session[:card_token].present?
      card_token = session.delete(:card_token)
      @user.update_card!(card_token)
      if session[:plan_id].present?
        plan_id = session.delete(:plan_id)
        @user.subscribe!(SubscriptionPlan.find(plan_id))
      end
    end
  end
end