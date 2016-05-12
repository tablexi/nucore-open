module Projects

  module ApplicationHelper

    def project_id_assignment_options(projects)
      blank_options + options_from_collection_for_select(projects, :id, :name)
    end

    private

    # TODO: I18n and move to the main app for use in order_detail_action_form
    def blank_options
      options_for_select([["Select project...", nil], ["Unassign", "unassign"]])
    end

  end

end
