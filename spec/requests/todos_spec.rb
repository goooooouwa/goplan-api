require "rails_helper"

RSpec.describe "Todos API", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:auth_headers) { bearer_headers_for(user) }

  describe "GET /todos" do
    it "returns 401 without a bearer token" do
      get "/todos", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns todos for the current user" do
      mine = create(:todo, project: project, name: "Task A")
      elsewhere = create(:todo, name: "Elsewhere")

      get "/todos", headers: auth_headers

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |t| t["id"] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(elsewhere.id)
    end
  end

  describe "POST /todos" do
    it "creates a todo" do
      expect do
        post "/todos",
             params: {
               todo: {
                 project_id: project.id,
                 name: "New task",
                 description: "Details",
                 start_date: "2022-02-01",
                 end_date: "2022-02-10"
               }
             },
             headers: auth_headers
      end.to change(Todo, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["name"]).to eq("New task")
    end

    it "returns 422 when validation fails" do
      expect do
        post "/todos",
             params: {
               todo: {
                 project_id: project.id,
                 name: "",
                 start_date: "2022-02-01",
                 end_date: "2022-02-10"
               }
             },
             headers: auth_headers
      end.not_to change(Todo, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /todos/:id" do
    it "redirects when the todo belongs to another user" do
      other_todo = create(:todo)

      get "/todos/#{other_todo.id}", headers: auth_headers

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "nested index actions" do
    let(:parent) { create(:todo, project: project) }
    let(:child) { create(:todo, project: project) }

    before do
      TodoChild.create!(todo_id: parent.id, child_id: child.id)
    end

    it "returns children for GET /todos/:id/children" do
      get "/todos/#{parent.id}/children", headers: auth_headers
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |t| t["id"] }
      expect(ids).to include(child.id)
    end
  end

  describe "DELETE /todos/:id" do
    it "removes the todo" do
      todo = create(:todo, project: project)

      expect do
        delete "/todos/#{todo.id}", headers: auth_headers
      end.to change(Todo, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
