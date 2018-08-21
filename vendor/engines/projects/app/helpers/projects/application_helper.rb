# frozen_string_literal: true

module Projects

  module ApplicationHelper

    def project_id_assignment_options(projects)
      blank_project_options + options_from_collection_for_select(projects, :id, :name)
    end

    private

    def blank_project_options
      options_for_select(
        [
          [I18n.t("projects.shared.select_project.placeholder"), nil],
          [I18n.t("projects.shared.select_project.unassign"), "unassign"],
        ],
      )
    end

  end

end
