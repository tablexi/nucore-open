module TransactionSearch

  class SearchForm
    include ActiveModel::Model

    attr_accessor :accounts, :account_owners, :statements, :date_range_field, :date_range_start, :date_range_end

    def self.model_name
      ActiveModel::Name.new(self, nil, "Search")
    end

    def [](field)
      if field == :date_ranges
        date_params
      else
        public_send(field)
      end
    end

    def date_params
      {
        field: date_range_field,
        start: date_range_start,
        end: date_range_end,
      }
    end

  end

end
