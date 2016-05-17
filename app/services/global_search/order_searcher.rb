module GlobalSearch

  class OrderSearcher

    include NUCore::Database::CaseSensitivityHelper

    attr_reader :facility, :query, :user

    def initialize(user = nil, facility = nil, query = nil)
      @user = user
      @facility = facility
      @query = query
    end

    def results
      @results ||= execute_search_query
    end

    private

    def execute_search_query
      return [] unless query.present?
      query.gsub!(/\s/, "")

      relation = case query
                 when /\A\d+-\d+\z/
                   search_full(query)
                 when /\A[A-Za-z]+-\d+\z/
                   search_external query
                 when /\A\d+\z/
                   OrderDetail.where("order_details.id = :id OR order_details.order_id = :id", id: query)
      end

      if relation
        restrict_to_user(relation.joins(:order).ordered)
      else
        []
      end
    end


    def search_full(query)
      order_id, order_detail_id = query.split("-")
      OrderDetail.where(id: order_detail_id, order_id: order_id)
    end

    def search_external(query)
      insensitive_where OrderDetail.joins(:external_service_receiver), "external_service_receivers.external_id", query
    end

    def restrict_to_user(items)
      items.select do |item|
        ability = Ability.new(user, item)
        ability.can? :show, item
      end
    end

  end

end
