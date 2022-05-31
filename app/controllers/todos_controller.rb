class TodosController < ApplicationController
  before_action :set_todo, only: %i[show update destroy]

  # GET /todos
  def index
    @todos = Todo.search(params)
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
    @todo.dependencies.delete_all   # avoid duplicate dependencies
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
  end

  # Only allow a list of trusted parameters through.
  def todo_params
    params.require(:todo).permit(:project_id, :name, :description, :status, :time_span, :start_date, :end_date, :repeat,
                                 :repeat_period, :repeat_times, :instance_time_span,
                                 todo_dependents_attributes: [:child_id],
                                 todo_dependencies_attributes: [:todo_id])
  end
end
