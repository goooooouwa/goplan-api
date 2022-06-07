class TodosController < ApplicationController
  before_action -> { doorkeeper_authorize! :write }
  before_action :set_todo, only: %i[show update update_dependencies destroy]

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

  # PATCH/PUT /todos/1/dependencies
  def update_dependencies
    @todo.dependencies = Todo.find todo_params[:dependencies_attributes]
    if @todo.save
      render 'todos/show'
    else
      render json: @todo.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /todos/1
  def update
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
                                 dependencies_attributes: [],
                                 todo_dependencies_attributes: [:todo_id])
  end
end
