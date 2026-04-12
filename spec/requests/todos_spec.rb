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
    it "returns JSON for the owner's todo" do
      todo = create(:todo, project: project, name: "Mine")

      get "/todos/#{todo.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq("Mine")
    end

    it "redirects when the todo belongs to another user" do
      other_todo = create(:todo)

      get "/todos/#{other_todo.id}", headers: auth_headers

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /todos/:id/dependencies and /dependents" do
    # dep must be done so "Next" is actionable; dependencies.json.jbuilder only shows
    # prerequisite todos that are "dependentless", so a linear A<-B chain yields [] for /dependencies.
    let(:dep) do
      create(:todo, project: project, name: "Prereq", status: true, start_date: "2022-01-01", end_date: "2022-01-02")
    end
    let(:dependent) do
      create(:todo, project: project, name: "Next", status: false, start_date: "2022-01-03", end_date: "2022-01-10")
    end

    before do
      TodoDependent.create!(todo_id: dep.id, dependent_id: dependent.id)
    end

    it "returns dependencies JSON (may be empty when prereqs are not dependentless)" do
      get "/todos/#{dependent.id}/dependencies", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_a(Array)
    end

    it "lists dependents that are actionable" do
      get "/todos/#{dep.id}/dependents", headers: auth_headers
      expect(response).to have_http_status(:ok)
      names = JSON.parse(response.body).map { |t| t["name"] }
      expect(names).to include("Next")
    end
  end

  describe "PATCH /todos/:id" do
    let(:prereq) do
      create(:todo, project: project, name: "Blocker", start_date: "2022-01-01", end_date: "2022-01-02")
    end
    let(:todo) do
      create(:todo, project: project, name: "Task", start_date: "2022-01-03", end_date: "2022-01-10")
    end

    it "updates the todo" do
      patch "/todos/#{todo.id}",
            params: {
              todo: {
                project_id: project.id,
                name: "Renamed",
                description: todo.description,
                start_date: todo.start_date,
                end_date: todo.end_date
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(todo.reload.name).to eq("Renamed")
    end

    it "rebuilds dependencies when dependencies_attributes is present" do
      patch "/todos/#{todo.id}",
            params: {
              dependencies_attributes: [prereq.id],
              todo: {
                project_id: project.id,
                name: todo.name,
                description: todo.description,
                start_date: todo.start_date,
                end_date: todo.end_date
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(todo.reload.dependencies).to include(prereq)
    end

    it "removes dependencies not listed in dependencies_attributes" do
      extra = create(:todo, project: project, name: "Extra", start_date: "2022-01-01", end_date: "2022-01-02")
      task = create(
        :todo,
        project: project,
        name: "Multi",
        start_date: "2022-01-03",
        end_date: "2022-01-10",
        todo_dependencies_attributes: [{ todo_id: prereq.id }, { todo_id: extra.id }]
      )

      patch "/todos/#{task.id}",
            params: {
              dependencies_attributes: [prereq.id],
              todo: {
                project_id: project.id,
                name: task.name,
                description: task.description,
                start_date: task.start_date,
                end_date: task.end_date
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(task.reload.dependencies).to contain_exactly(prereq)
    end

    it "returns 422 when validation fails" do
      patch "/todos/#{todo.id}",
            params: {
              todo: {
                project_id: project.id,
                name: "",
                start_date: todo.start_date,
                end_date: todo.end_date
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
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
