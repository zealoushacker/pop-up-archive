class ApplicationController < ActionController::Base
  force_ssl if: :ssl_configured?

  protect_from_forgery

  # decent_configuration do
  #   strategy DecentExposure::StrongParametersStrategy
  # end

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to root_url
  end

  private
  def ssl_configured?
    !Rails.env.development?
  end

end
