module Projects

  class ProjectsController < ApplicationController

    admin_tab :all
    before_filter { @active_tab = "admin_projects" }

    load_and_authorize_resource

    def index
      @projects = current_facility.projects
    end

    def new
      @project = Projects::Project.new(facility: current_facility)
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

    private

    def project_params
      params.require(:projects_project).permit("description", "name")
    end

  end
end
