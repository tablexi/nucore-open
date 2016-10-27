module BulkEmail

  class Job < ActiveRecord::Base

    self.table_name = "bulk_email_jobs"

    belongs_to :facility, foreign_key: :facility_id

    serialize :recipients, Array
    serialize :search_criteria, Hash

    validates :facility_id, :sender, :subject, :recipients, :search_criteria, presence: true

  end

end
