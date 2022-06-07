class ProjectsController < ApiController
  before_action -> { doorkeeper_authorize! :write }
  before_action :set_project, only: %i[show update destroy]

  # GET /projects
  def index
    @projects = current_resource_owner.projects.search(params)
  end

  # GET /projects/1
  def show; end

  # POST /projects
  def create
    @project = Project.new(project_params)

    if @project.save
      render 'projects/show', status: :created, location: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /projects/1
  def update
    if @project.update(project_params)
      render 'projects/show'
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # DELETE /projects/1
  def destroy
    @project.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
    redirect_to root_path if current_resource_owner != @project.user
  end

  # Only allow a list of trusted parameters through.
  def project_params
    params.require(:project).permit(:user_id, :name, :target_date)
  end
end
