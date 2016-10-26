module BulkEmail

  class Job < ActiveRecord::Base

    self.table_name = "bulk_email_jobs"

    validates :sender, :subject, presence: true
    validates_with JobJsonFieldValidator

    def search_criteria=(value)
      if value.is_a?(Hash)
        self.search_criteria = value.to_json
      else
        super
      end
    end

  end

end
