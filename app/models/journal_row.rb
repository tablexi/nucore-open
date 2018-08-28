# frozen_string_literal: true

class JournalRow < ApplicationRecord

  belongs_to :journal
  belongs_to :order_detail

  validates_presence_of :journal_id, :amount
  validates_presence_of :account if SettingsHelper.feature_on? :expense_accounts

  delegate :fulfilled_at, to: :order_detail, allow_nil: true

  def update_amount
    update_attributes(amount: order_detail.actual_cost)
  end

end
