# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  before_action -> { doorkeeper_authorize! :write }, only: %i[destroy_with_token]
  skip_before_action :verify_authenticity_token, :only => %i[destroy_with_token]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # DELETE /resource/sign_out_with_token
  def destroy_with_token
    if current_user
      sign_out current_user
    end
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def current_user
    @current_user ||= User.find_by(id: doorkeeper_token.resource_owner_id)
  end
end
