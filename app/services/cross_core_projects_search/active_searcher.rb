# frozen_string_literal: true

module CrossCoreProjectsSearch

  class ActiveSearcher < BaseSearcher
    def options
      ["active", "inactive"]
    end

    def search(params)
      return projects if params.blank?

      if params == "inactive"
        projects.inactive
      else
        projects.active
      end
    end

    def label_method
      :humanize
    end

    def label
      # TODO: Use i18n
      "Active/Inactive"
    end

    def input_type
      :select
    end

  end

end
