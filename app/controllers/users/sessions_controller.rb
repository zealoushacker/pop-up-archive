class Users::SessionsController < Devise::SessionsController

	def new
    session.delete(:card_token)
    session.delete(:plan_id)
    session[:user_return_to] = params[:return_to] if params[:return_to].present?
    super
	end

end