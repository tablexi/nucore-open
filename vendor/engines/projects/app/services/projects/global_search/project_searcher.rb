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
        return [] if query.blank?
        query_object.where("lower(name) LIKE ?", "%#{query.downcase}%").select do |project|
          Ability.new(user, project).can?(:show, project)
        end
      end

    end

  end

end
