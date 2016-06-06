module SangerSequencing

  class Submission < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    validates :savable_samples, length: { minimum: 1 }, on: :update

    self.table_name = "sanger_sequencing_submissions"
    belongs_to :order_detail
    has_many :samples
    accepts_nested_attributes_for :samples, allow_destroy: true

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
