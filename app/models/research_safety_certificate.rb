# frozen_string_literal: true

class ResearchSafetyCertificate < ApplicationRecord

  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :deleted_by, class_name: 'User'

  acts_as_paranoid # soft-delete functionality

  validates :name, presence: true
  validates :name, uniqueness: { scope: :deleted_at }

  has_many :product_certification_requirements, class_name: "ProductResearchSafetyCertificationRequirement",
                                                dependent: :destroy
  has_many :products, through: :product_certification_requirements

  scope :ordered, -> { order(:name) }

end


