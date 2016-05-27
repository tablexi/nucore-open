module SangerSequencing

  class Submission < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    self.table_name = "sanger_sequencing_submissions"
    belongs_to :order_detail
    has_many :samples
    accepts_nested_attributes_for :samples

  end

end
