class TodosController < ApiController
  before_action -> { doorkeeper_authorize! :write }
  before_action :set_todo, only: %i[show update children dependencies dependents destroy]

  # GET /todos
  def index
    @todos = current_resource_owner.todos.search(params)
  end

  # GET /todos/1/children
  def children
    @todos = @todo.children.search(params)
  end

  # GET /todos/1/dependencies
  def dependencies
    @todos = @todo.dependencies.search(params)
  end

  # GET /todos/1/dependents
  def dependents
    @todos = @todo.dependents.search(params)
  end

  # GET /todos/1
  def show; end

  # POST /todos
  def create
    @todo = Todo.new(todo_params)
    
    if @todo.save
      render 'todos/show', status: :created, location: @todo
    else
      render json: @todo.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /todos/1
  def update
    unless params[:dependencies_attributes].nil?
      params[:todo][:todo_dependencies_attributes] =
        build_todo_dependencies_attributes(@todo, params[:dependencies_attributes])
    end

    if @todo.update(todo_params)
      render 'todos/show'
    else
      render json: @todo.errors, status: :unprocessable_entity
    end
  end

  # DELETE /todos/1
  def destroy
    @todo.destroy
  end

  private

  def build_todo_dependencies_attributes(todo, dependencies_attributes)
    todo_dependencies_attributes = []

    to_be_destroyed = todo.todo_dependencies.where.not(todo_id: dependencies_attributes)
    to_be_destroyed.each do |todo_dependency|
      todo_dependencies_attributes << {
        id: todo_dependency.id,
        _destroy: '1'
      }
    end

    new_dependencies = Todo.find dependencies_attributes
    new_dependencies.each do |dependency|
      todo_dependency = TodoDependent.find_by todo_id: dependency.id, dependent_id: todo.id
      todo_dependencies_attributes << {
        id: todo_dependency.nil? ? nil : todo_dependency.id,
        todo_id: dependency.id
      }.compact
    end

    todo_dependencies_attributes
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_todo
    @todo = Todo.find(params[:id])
    redirect_to root_path if current_resource_owner != @todo.project.user
  end

  # Only allow a list of trusted parameters through.
  def todo_params
    params.require(:todo).permit(:project_id, :name, :description, :color, :status, :start_date, :end_date, :repeat,
                                 :week, :month, :quarter, :year,
                                 :repeat_period, :repeat_times, :instance_time_span,
                                 children_attributes: [:id, :project_id, :name, :color, :start_date, :end_date, :status, :_destroy],
                                 todo_dependents_attributes: [:id, :dependent_id, :_destroy],
                                 todo_dependencies_attributes: [:id, :todo_id, :_destroy])
  end
end
