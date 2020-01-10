# frozen_string_literal: true

module Reports

  class AccountSearchCsv

    include Reports::CsvExporter

    def initialize(accounts, exclude_facilities: false)
      @accounts = accounts
    end

    def report_data_query
      @accounts
    end

    private

    def report_hash
      hash = {
        Account.model_name.human => :to_s,
        Facility.model_name.human => ->(account) { show_facilities(account) },
        Account.human_attribute_name(:suspended_at) => ->(account) { format_usa_date(account.suspended_at) },
        Account.human_attribute_name(:owner) => ->(account) { account.owner_user.to_s },
        Account.human_attribute_name(:expires_at) => ->(account) { format_usa_date(account.expires_at) },
      }
      hash
    end

    def column_headers
      report_hash.keys
    end

    private

    def show_facilities(account)
      account.facilities.any? ? account.facilities.join(", ") : I18n.t("shared.all")
    end
  end

end
