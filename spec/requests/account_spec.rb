require "rails_helper"

RSpec.describe "Account API", type: :request do
  let(:user) { create(:user, name: "Ada", image_url: "https://example.com/a.png") }
  let(:auth_headers) { bearer_headers_for(user) }

  describe "GET /me" do
    it "returns 401 without a bearer token" do
      get "/me", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the authenticated user as JSON" do
      get "/me", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["email"]).to eq(user.email)
      expect(json["name"]).to eq("Ada")
      expect(json["imageUrl"]).to eq("https://example.com/a.png")
    end
  end

  describe "PUT /me" do
    it "updates allowed profile fields" do
      put "/me",
          params: { user: { name: "Updated", image_url: "https://example.com/b.png" } },
          headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Updated")
      expect(json["imageUrl"]).to eq("https://example.com/b.png")
      expect(user.reload.name).to eq("Updated")
    end
  end
end
