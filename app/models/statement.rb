# frozen_string_literal: true

class Statement < ApplicationRecord

  has_many :order_details, inverse_of: :statement
  has_many :statement_rows, dependent: :destroy
  has_many :payments, inverse_of: :statement

  belongs_to :account
  belongs_to :facility
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by

  validates_numericality_of :account_id, :facility_id, :created_by, only_integer: true

  default_scope -> { order(created_at: :desc) }

  # Used in NU branch
  def first_order_detail_date
    min_order = order_details.min { |a, b| a.order.ordered_at <=> b.order.ordered_at }
    min_order.order.ordered_at
  end

  def total_cost
    statement_rows.inject(0) { |sum, row| sum += row.amount }
  end

  def invoice_number
    "#{account_id}-#{id}"
  end

  def self.find_by_statement_id(query)
    return nil unless /\A(?<id>\d+)\z/ =~ query
    find_by(id: id)
  end

  def self.find_by_invoice_number(query)
    return nil unless /\A(?<account_id>\d+)-(?<id>\d+)\z/ =~ query
    find_by(id: id, account_id: account_id)
  end

  def self.for_facility(facility)
    if facility.single_facility?
      where(facility: facility)
    else
      all
    end
  end

  def invoice_date
    created_at.to_date
  end

  def reconciled?
    order_details.where("state <> ?", "reconciled").empty?
  end

  def paid_in_full?
    payments.sum(:amount) >= total_cost
  end

  def add_order_detail(order_detail)
    statement_rows << StatementRow.new(order_detail: order_detail)
    order_details << order_detail
  end

  def remove_order_detail(order_detail)
    rows_for_order_detail(order_detail).each(&:destroy)
  end

  def rows_for_order_detail(order_detail)
    statement_rows.where(order_detail_id: order_detail.id)
  end

end
