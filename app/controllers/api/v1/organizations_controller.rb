class Api::V1::OrganizationsController < Api::V1::BaseController
  expose(:organization)

  authorize_resource decent_exposure: true

  def show
    respond_with :api, organization
  end

end
