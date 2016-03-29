module Projects

  class ProjectsController < ApplicationController

    load_and_authorize_resource

    def index
      @projects = current_facility.projects
    end

    def new
      @project = Projects::Project.new(facility: current_facility)
    end

    def create
      @project = current_facility.projects.new(params[:projects_project])
      if @project.save
        flash[:notice] =
         I18n.t("controllers.projects.projects.create.success", project_name: @project.name)
        redirect_to facility_projects_path(current_facility)
      else
        render action: :new
      end
    end
  end
end
