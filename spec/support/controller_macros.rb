module ControllerMacros
  def login_user
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @logged_in_user = FactoryGirl.create(:user)
      sign_in @logged_in_user
    end
  end

  def logged_in_user
    @logged_in_user
  end

end