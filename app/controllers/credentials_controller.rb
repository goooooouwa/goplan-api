class CredentialsController < ApplicationController
  respond_to :json

  # GET /me.json
  def me
    respond_with current_resource_owner
  end
end
