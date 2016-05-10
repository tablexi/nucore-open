module Projects

  class ProjectSearcher < TransactionSearch::BaseSearcher

    def options
      Project.where(id: order_details.select("distinct project_id")).order(:name)
    end

    def search(params)
      if params.present?
        order_details.where(project_id: params)
      else
        order_details
      end
    end

  end

end
