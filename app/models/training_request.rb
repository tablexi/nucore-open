class TrainingRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :product

  validates_presence_of :user, :product
  validates :user_id, uniqueness: { scope: :product_id }

  validates_with ProductRequiresApprovalValidator

  def self.submitted?(user, product)
    where(product_id: product.id, user_id: user.id).present?
  end

  def self.for_facility(facility)
    joins(:product).where(products: { facility_id: facility.id })
  end
end
