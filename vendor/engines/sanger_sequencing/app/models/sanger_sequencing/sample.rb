# frozen_string_literal: true

module SangerSequencing

  class Sample < ApplicationRecord

    self.table_name = "sanger_sequencing_samples"
    belongs_to :submission

    validates :customer_sample_id, presence: true

    default_scope { order(:id) }

    def form_customer_sample_id
      customer_sample_id || default_customer_sample_id
    end

    def reserved?
      false
    end

    def results_files
      submission.order_detail.sample_results_files.select { |file| file.name.start_with?("#{id}_") }
    end

    private

    def default_customer_sample_id
      number = id || Time.now.to_i
      ("%04d" % number).last(4)
    end

  end

end
