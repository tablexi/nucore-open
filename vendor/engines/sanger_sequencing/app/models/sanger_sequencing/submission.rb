module SangerSequencing

  class Submission < ActiveRecord::Base

    self.table_name = "sanger_sequencing_submissions"

    include ActiveModel::ForbiddenAttributesProtection

    validates :savable_samples, length: { minimum: 1 }, on: :update

    belongs_to :order_detail, class_name: "::OrderDetail"
    has_one :order, through: :order_detail
    has_one :user, through: :order
    has_one :facility, through: :order
    has_many :samples

    accepts_nested_attributes_for :samples, allow_destroy: true

    delegate :order_id, :user, :order_status, to: :order_detail
    delegate :purchased?, :ordered_at, to: :order
    alias purchased_at ordered_at

    scope :purchased, -> { joins(:order).merge(Order.purchased.order(:ordered_at)) }
    scope :for_facility, -> (facility) { where(orders: { facility_id: facility.id }) }

    def create_samples!(quantity)
      quantity = quantity.to_i
      raise ArgumentError, "quantity must be positive" if quantity <= 0
      transaction do
        Array.new(quantity) { samples.create! }
      end
    end

    private

    def savable_samples
      samples.reject(&:marked_for_destruction?)
    end

  end

end
