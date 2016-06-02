module SangerSequencing

  class Submission < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    validates :savable_samples, length: { minimum: 1 }, on: :update

    self.table_name = "sanger_sequencing_submissions"
    belongs_to :order_detail
    has_many :samples
    accepts_nested_attributes_for :samples

    private

    def savable_samples
      samples.reject(&:marked_for_destruction?)
    end

  end

end
