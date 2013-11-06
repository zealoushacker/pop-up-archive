class Admin::AccountsController < Admin::BaseController

  def index
    @accounts = User.over_limits
  end

end
