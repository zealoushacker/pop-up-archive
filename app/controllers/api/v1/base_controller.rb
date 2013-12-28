class Api::V1::BaseController < Api::BaseController

  include Doorkeeper::Helpers::AdditionalFilter

  respond_to :json

  # this should protect the resources using oauth when user is not logged in (i.e. API requests)
  # doorkeeper_for :create, :update, :destroy, if: lambda{ |c| !current_user }
  doorkeeper_for :create, :destroy, if: lambda{ |c| !current_user }

  doorkeeper_try :all, except: [:create, :update, :destroy], if: lambda{ |c| !current_user }

  # use either the devise or oauth user as current_user
  def current_user_with_oauth
    current_user_without_oauth || current_oauth_user
  end

  def current_oauth_user
    @current_oauth_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  alias_method_chain :current_user, :oauth

end
