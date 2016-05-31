module SangerSequencing

  class Sample < ActiveRecord::Base

    self.table_name = "sanger_sequencing_samples"
    belongs_to :submission

  end

end
