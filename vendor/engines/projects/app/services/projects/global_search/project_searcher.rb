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

      def search
        query_object.where("lower(name) LIKE ?", "%#{query.downcase}%")
      end

    end

  end

end
