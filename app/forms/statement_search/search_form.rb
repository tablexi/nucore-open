# frozen_string_literal: true

module StatementSearch

  class SearchForm

    include ActiveModel::Model

    attr_reader :params
    attr_accessor :date_range_start, :date_range_end, :date_ranges,
                  :facilities, :accounts, :sent_tos, :status

    # def self.model_name
    #   ActiveModel::Name.new(self, nil, "Search")
    # end

    def initialize(params)
      @params = params
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
        field: "created_at",
        start: date_range_start,
        end: date_range_end,
      }
    end

  end

end
