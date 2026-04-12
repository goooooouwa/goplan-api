require "rails_helper"

RSpec.describe "User profile", type: :request do
  let(:user) { create(:user) }

  it "requires sign-in" do
    get "/profile"
    expect(response).to have_http_status(:redirect)
  end

  it "shows the profile when signed in" do
    sign_in user
    get "/profile"
    expect(response).to have_http_status(:ok)
  end

  it "applies locale from params when switching locale" do
    sign_in user
    get "/profile", params: { locale: "en" }
    expect(response).to have_http_status(:ok)
  end
end
