module TransactionSearch

  class SearchForm
    include ActiveModel::Model

    attr_accessor :date_range_field, :date_range_start, :date_range_end
    attr_accessor :facilities, :accounts, :products, :account_owners,
                  :order_statuses, :statements, :date_ranges

    def self.model_name
      ActiveModel::Name.new(self, nil, "Search")
    end

    def initialize(params, defaults: default_params)
      super(params.to_h.reverse_merge(defaults))
    end

    def [](field)
      if field == :date_ranges
        date_params
      else
        public_send(field)
      end
    end


    private

    def date_params
      {
        field: date_range_field,
        start: date_range_start,
        end: date_range_end,
      }
    end

    def default_params
      {
        date_range_field: "fulfilled_at",
      }
    end

  end

end
