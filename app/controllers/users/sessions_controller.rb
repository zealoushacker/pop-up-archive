class Users::SessionsController < Devise::SessionsController

	def new
    session.delete(:card_token)
    session.delete(:plan_id)
    super
	end

end