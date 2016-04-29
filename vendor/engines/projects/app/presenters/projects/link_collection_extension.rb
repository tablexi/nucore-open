module Projects

  module LinkCollectionExtension

    extend ActiveSupport::Concern

    included do
      tab_methods << :admin_projects
    end

    def admin_projects
      if single_facility? && ability.can?(:index, Project)
        NavTab::Link.new(
          tab: :admin_projects,
          text: Project.model_name.human(count: 2),
          url: facility_projects_path(facility),
        )
      end
    end

  end

end
