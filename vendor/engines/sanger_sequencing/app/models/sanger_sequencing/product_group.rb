module SangerSequencing

  class ProductGroup < ActiveRecord::Base

    self.table_name = "sanger_sequencing_product_groups"
    GROUPS = WellPlateConfiguration::CONFIGS.keys

    belongs_to :product

    validates :group, presence: true, inclusion: { in: GROUPS }
    validates :product, presence: true, uniqueness: true

  end

end
