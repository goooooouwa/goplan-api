require "rails_helper"

RSpec.describe "OmniAuth callbacks", type: :request do
  before { OmniAuth.config.test_mode = true }

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.clear
  end

  def github_auth(email: "oauth@example.com")
    OmniAuth::AuthHash.new(
      provider: "github",
      uid: "github-test-uid",
      info: { email: email, name: "OAuth User", image: "https://example.com/img.png" }
    )
  end

  it "creates and signs in a user via GitHub" do
    OmniAuth.config.mock_auth[:github] = github_auth

    expect do
      get "/users/auth/github/callback"
    end.to change(User, :count).by(1)

    expect(response).to have_http_status(:redirect)
    expect(User.find_by(provider: "github", uid: "github-test-uid")).to be_present
  end

  it "creates and signs in a user via Google" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-test-uid",
      info: { email: "google@example.com", name: "OAuth User", image: "https://example.com/img.png" }
    )

    expect do
      get "/users/auth/google_oauth2/callback"
    end.to change(User, :count).by(1)

    expect(response).to have_http_status(:redirect)
    expect(User.find_by(provider: "google_oauth2", uid: "google-test-uid")).to be_present
  end

  it "redirects to root from the failure action" do
    get "/oauth_failure"
    expect(response).to have_http_status(:redirect)
  end

  it "redirects to sign up when the user is not persisted" do
    OmniAuth.config.mock_auth[:github] = github_auth
    unsaved = User.new
    allow(User).to receive(:from_omniauth).and_return(unsaved)
    allow(unsaved).to receive(:persisted?).and_return(false)

    get "/users/auth/github/callback"

    expect(response).to redirect_to(%r{/users/sign_up})
  end
end
