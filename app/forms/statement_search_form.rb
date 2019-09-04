# frozen_string_literal: true

class StatementSearchForm

  include DateHelper
  include ActiveModel::Model

  attr_accessor :accounts, :facility, :sent_to, :date_range_start, :date_range_end

  def available_accounts
    Account.where(id: all_statements.select(:account_id).distinct).order(:account_number, :description)
  end

  def available_sent_to
    User.where(id: available_accounts.joins(:notify_users).select("account_users.user_id").distinct).order(:last_name, :first_name)
  end

  def search
    all_statements.for_accounts(accounts)
                  .for_sent_to(sent_to)
                  .created_between(parse_usa_date(date_range_start)&.beginning_of_day, parse_usa_date(date_range_end)&.end_of_day)
  end

  private

  def all_statements
    Statement.for_facility(facility)
  end

end
