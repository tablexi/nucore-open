module Projects

  class ProjectsController < ApplicationController

    admin_tab :all
    before_filter { @active_tab = "admin_projects" }

    load_and_authorize_resource through: :current_facility

    def index
      @projects = @projects.paginate(page: params[:page])
    end

    def new
    end

    def create
      @project = current_facility.projects.new(project_params)
      if @project.save
        flash[:notice] =
          I18n.t("controllers.projects.projects.create.success", project_name: @project.name)
        redirect_to facility_projects_path(current_facility)
      else
        render action: :new
      end
    end

    def edit
    end

    def show
    end

    def update
      @project.attributes = project_params
      if @project.save
        flash[:notice] =
          I18n.t("controllers.projects.projects.update.success", project_name: @project.name)
        redirect_to facility_projects_path(@project.facility)
      else
        render action: :edit
      end
    end

    private

    def project_params
      params.require(:projects_project).permit("description", "name")
    end

  end

end
