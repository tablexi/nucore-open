module SangerSequencing

  class Submission < ActiveRecord::Base

    self.table_name = "sanger_sequencing_submissions"
    belongs_to :order_detail
    has_many :samples

  end

end
