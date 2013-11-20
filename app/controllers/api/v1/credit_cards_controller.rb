class Api::V1::CreditCardsController < Api::V1::BaseController

  def update
    current_user.update_card!(params[:credit_card][:token])
    render status: 200, json: {status: 'OK'}
  end

  def save_token
  	session[:card_token] = params[:token_id]
  	session[:plan_id] = params[:plan_id]
  	render status: 200, json: {status: 'OK'}
  end

end
