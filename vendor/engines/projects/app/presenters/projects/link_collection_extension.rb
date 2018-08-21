# frozen_string_literal: true

module Projects

  module LinkCollectionExtension

    extend ActiveSupport::Concern

    included do
      insert_index = tab_methods.index(:admin_facility) || -1
      tab_methods.insert(insert_index, :admin_projects)
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
