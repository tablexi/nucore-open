module SangerSequencing

  class Sample < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    self.table_name = "sanger_sequencing_samples"
    belongs_to :submission

    validates :customer_sample_id, presence: true, on: :update

    def customer_sample_id
      self[:customer_sample_id] || (id && default_customer_sample_id)
    end

    private

    def default_customer_sample_id
      # last four digits of the id as a zero-padded string
      format("%04d", id).last(4)
    end

  end

end
