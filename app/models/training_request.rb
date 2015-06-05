class TrainingRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :product

  validates_presence_of :user, :product
  validates :user_id, uniqueness: { scope: :product_id }

  validates_with ProductRequiresApprovalValidator
end
