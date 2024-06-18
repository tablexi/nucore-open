# frozen_string_literal: true

module CrossCoreProjectsSearch

  class CrossCoreSearcher < BaseSearcher
    def options
      ["no", "yes"]
    end

    def search(params)
      if params == "yes"
        cross_core_projects
      else
        single_facility_projects
      end
    end

    def label_method
      :humanize
    end

    def label
      I18n.t("projects.index.cross_core_searcher.label")
    end

    def input_type
      :select
    end

    private

    def cross_core_projects
      Projects::Project
        .joins(:orders)
        .where(orders: { facility_id: @current_facility_id })
    end

    def single_facility_projects
      Projects::Project
        .left_outer_joins(orders: [:facility, :cross_core_project])
        .where(orders: { cross_core_project_id: nil })
        .where(facility_id: @current_facility_id)
    end

  end

end
