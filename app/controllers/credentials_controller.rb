class CredentialsController < ApiController
  before_action -> { doorkeeper_authorize! :write }

  # GET /me.json
  def me
    @user = current_resource_owner
    render "users/show"
  end
end
