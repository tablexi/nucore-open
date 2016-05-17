module Projects

  module GlobalSearch

    class ProjectSearcher

      include ::GlobalSearch::Common

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
        query_object.where(name: query).select do |project|
          Ability.new(user, project).can?(:show, project)
        end
      end

      def sanitize_search_string(search_string)
        search_string.to_s.strip
      end

    end

  end

end
