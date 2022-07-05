class TodosController < ApiController
  before_action -> { doorkeeper_authorize! :write }
  before_action :set_todo, only: %i[show update update_dependencies destroy]

  # GET /todos
  def index
    @todos = current_resource_owner.todos.search(params).order(:status, created_at: :desc)
  end

  # GET /todos/children
  def children
    @todos = current_resource_owner.todos.search(params)
  end

  # GET /todos/dependencies
  def dependencies
    @todos = current_resource_owner.todos.search(params)
  end

  # GET /todos/dependents
  def dependents
    @todos = current_resource_owner.todos.search(params)
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
    
    binding.pry
    
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

  # Use callbacks to share common setup or constraints between actions.
  def set_todo
    @todo = Todo.find(params[:id])
    redirect_to root_path if current_resource_owner != @todo.project.user
  end

  # Only allow a list of trusted parameters through.
  def todo_params
    params.require(:todo).permit(:project_id, :name, :description, :status, :time_span, :start_date, :end_date, :repeat,
                                 :repeat_period, :repeat_times, :instance_time_span,
                                 children_attributes: [:id, :project_id, :name, :start_date, :end_date, :status, :instance_time_span, :_destroy],
                                 dependents_attributes: [:id, :_destroy],
                                 dependencies_attributes: [:id, :_destroy])
  end
end
