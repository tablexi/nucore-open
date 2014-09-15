class ChartStringReassignmentForm
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_reader :account_id, :available_accounts, :order_details

  def initialize(order_details)
    @order_details = order_details
    @available_accounts = available_accounts
  end

  def available_accounts?
    @available_accounts.any?
  end

  def available_accounts
    @order_details
    .map(&:user)
    .map(&:accounts)
    .flatten
    .uniq
    .select { |account| account.facility.nil? || account.facility == facility }
    .sort_by(&:description)
  end

  def persisted?
    false
  end

  def facility
    @facility ||= @order_details.first.facility
  end
end
