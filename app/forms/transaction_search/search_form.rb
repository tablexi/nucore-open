module TransactionSearch

  class SearchForm

    include ActiveModel::Model

    attr_accessor :date_range_field, :date_range_start, :date_range_end
    attr_accessor :facilities, :accounts, :products, :account_owners,
                  :order_statuses, :statements, :date_ranges, :ordered_fors

    def self.model_name
      ActiveModel::Name.new(self, nil, "Search")
    end

    def initialize(params, defaults: default_params)
      # If defaults are given, they are merged with the default_params (so we have
      # everything needed, even if the provided defaults are missing one of our
      # defaults.
      full_defaults = defaults.reverse_merge(default_params)
      super(Hash(params).reverse_merge(full_defaults))
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

    private

    def default_params
      {
        date_range_field: "fulfilled_at",
      }
    end

  end

end
