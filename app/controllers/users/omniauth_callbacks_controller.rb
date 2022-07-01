class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: [:github, :google_oauth2]

  def github
    callback
  end

  def google_oauth2
    callback
  end

  def wechat
    callback
  end

  def failure
    redirect_to root_path
  end

  private

  def callback
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env['omniauth.auth']
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
    else
      session['devise.oauth.data'] = request.env['omniauth.auth'].with_indifferent_access.except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url
    end
  end
end
