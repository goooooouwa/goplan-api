require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:user) { create(:user) }

  it "requires sign-in" do
    get "/home"
    expect(response).to have_http_status(:redirect)
  end

  it "renders when signed in" do
    sign_in user
    get "/home"
    expect(response).to have_http_status(:ok)
  end
end
