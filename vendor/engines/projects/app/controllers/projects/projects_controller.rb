module Projects

  class ProjectsController < ApplicationController

    admin_tab :all
    before_filter { @active_tab = "admin_projects" }

    load_and_authorize_resource through: :current_facility

    def index
      filter_projects_for_index
      @active_project_count = Project.active.count
      @inactive_project_count = Project.inactive.count
    end

    def new
    end

    def backend?
      true
    end

    def create
      @project = current_facility.projects.new(project_params)
      render action: :new unless save_project
    end

    def edit
    end

    def show
    end

    def update
      @project.attributes = project_params
      render action: :edit unless save_project
    end

    def showing_archived?
      params[:archived] == "true"
    end
    helper_method :showing_archived?

    private

    def project_params
      params.require(:projects_project).permit("active", "description", "name")
    end

    def save_project
      if @project.save
        flash[:notice] =
          I18n.t("controllers.projects.projects.#{action_name}.success", project_name: @project.name)
        redirect_to facility_projects_path(@project.facility)
      end
    end

    def filter_projects_for_index
      @projects = showing_archived? ? @projects.inactive : @projects.active
      @projects = @projects.paginate(page: params[:page])
    end

  end

end
