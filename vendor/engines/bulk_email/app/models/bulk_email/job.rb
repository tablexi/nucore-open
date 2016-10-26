module BulkEmail

  class Job < ActiveRecord::Base

    self.table_name = "bulk_email_jobs"

    serialize :recipients, Array
    serialize :search_criteria, Hash

    validates :sender, :subject, :recipients, :search_criteria, presence: true

  end

end
