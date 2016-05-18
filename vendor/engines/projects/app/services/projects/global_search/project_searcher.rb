module Projects

  module GlobalSearch

    class ProjectSearcher < ::GlobalSearch::Base

      def template
        "projects"
      end

      private

      def query_object
        if facility.try(:single_facility?)
          facility.projects
        else
          Projects::Project
        end
      end

      def execute_search_query
        query_object.where("lower(name) = ?", query).select do |project|
          Ability.new(user, project).can?(:show, project)
        end
      end

      def sanitize_search_string(search_string)
        search_string.to_s.strip.downcase
      end

    end

  end

end
