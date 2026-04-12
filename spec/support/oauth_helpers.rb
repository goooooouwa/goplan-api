module OauthHelpers
  def oauth_application
    @oauth_application ||= Doorkeeper::Application.create!(
      name: "RSpec client",
      redirect_uri: "https://example.com/callback",
      scopes: "write",
      confidential: false
    )
  end

  def bearer_headers_for(user, scopes: "write")
    token = Doorkeeper::AccessToken.create!(
      application: oauth_application,
      resource_owner_id: user.id,
      scopes: scopes
    )
    {
      "Authorization" => "Bearer #{token.token}",
      "Accept" => "application/json"
    }
  end
end

RSpec.configure do |config|
  config.include OauthHelpers, type: :request
end
