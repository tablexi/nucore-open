module SangerSequencing

  class Sample < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    self.table_name = "sanger_sequencing_samples"
    belongs_to :submission
    # customer_sample_id is based off of the ID, which we don't have until
    # after the initial persistence.
    after_create { customer_sample_id && save }

    def customer_sample_id
      self[:customer_sample_id] ||= default_customer_sample_id
    end

    private

    def default_customer_sample_id
      # last four digits of the id as a zero-padded string
      format("%04d", id).last(4)
    end

  end

end
