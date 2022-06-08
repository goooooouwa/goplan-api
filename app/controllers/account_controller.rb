class AccountController < ApiController
  wrap_parameters User
  before_action -> { doorkeeper_authorize! :write }
  before_action :set_user, only: %i[show update]

  # GET /me.json
  def show
    render 'users/show'
  end

  # PATCH/PUT /me.json
  def update
    if @user.update(user_params)
      render 'users/show'
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_resource_owner
  end

  def user_params
    params.require(:user).permit(:name, :image_url)
  end
end
