class Api::V1::CreditCardsController < Api::V1::BaseController

  def update
    current_user.update_card!(params[:credit_card][:token])
    render status: 200, json: {status: 'OK'}
  end

end
