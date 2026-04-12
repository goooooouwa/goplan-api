require "rails_helper"

RSpec.describe "Projects API", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { bearer_headers_for(user) }

  describe "GET /projects" do
    it "returns 401 without a bearer token" do
      get "/projects", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the current user's projects" do
      mine = create(:project, user: user, name: "Mine")
      not_mine = create(:project, name: "Theirs")

      get "/projects", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body.map { |p| p["id"] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(not_mine.id)
    end
  end

  describe "POST /projects" do
    it "creates a project for the given user" do
      target = Time.zone.parse("2025-06-01")

      expect do
        post "/projects",
             params: { project: { name: "Roadmap", target_date: target } },
             headers: auth_headers
      end.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Roadmap")
      expect(Project.last.user_id).to eq(user.id)
    end

    it "ignores a spoofed user_id and always assigns the OAuth user" do
      other = create(:user)
      target = Time.zone.parse("2025-06-01")

      post "/projects",
           params: { project: { user_id: other.id, name: "Hijack", target_date: target } },
           headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(Project.last.user_id).to eq(user.id)
      expect(Project.last.user_id).not_to eq(other.id)
    end

    it "returns 422 when validation fails" do
      expect do
        post "/projects",
             params: { project: { name: "" } },
             headers: auth_headers
      end.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /projects/:id" do
    it "returns JSON for the owner's project" do
      project = create(:project, user: user, name: "Owned")

      get "/projects/#{project.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq("Owned")
    end

    it "redirects when the project belongs to another user" do
      other_project = create(:project)

      get "/projects/#{other_project.id}", headers: auth_headers

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /projects/:id" do
    it "updates the project" do
      project = create(:project, user: user, name: "Old")

      patch "/projects/#{project.id}",
            params: { project: { name: "New", target_date: project.target_date } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(project.reload.name).to eq("New")
    end

    it "does not reassign the project to another user via user_id" do
      project = create(:project, user: user, name: "Owned")
      other = create(:user)

      patch "/projects/#{project.id}",
            params: { project: { user_id: other.id, name: "Still mine", target_date: project.target_date } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(project.reload.user_id).to eq(user.id)
      expect(project.user_id).not_to eq(other.id)
    end

    it "returns 422 when validation fails" do
      project = create(:project, user: user)

      patch "/projects/#{project.id}",
            params: { project: { name: "" } },
            headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /projects/:id" do
    it "removes the project" do
      project = create(:project, user: user)

      expect do
        delete "/projects/#{project.id}", headers: auth_headers
      end.to change(Project, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
