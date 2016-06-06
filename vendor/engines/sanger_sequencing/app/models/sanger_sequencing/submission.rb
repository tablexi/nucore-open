module SangerSequencing

  class Submission < ActiveRecord::Base

    self.table_name = "sanger_sequencing_submissions"

    include ActiveModel::ForbiddenAttributesProtection

    validates :savable_samples, length: { minimum: 1 }, on: :update

    belongs_to :order_detail, class_name: "::OrderDetail"
    has_one :order, through: :order_detail
    has_one :user, through: :order
    has_many :samples

    accepts_nested_attributes_for :samples, allow_destroy: true

    delegate :order_id, to: :order_detail

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
