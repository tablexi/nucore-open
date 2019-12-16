# frozen_string_literal: true

class ProductResearchSafetyCertificationRequirement < ApplicationRecord

  self.table_name = "nu_product_cert_requirements"

  acts_as_paranoid # soft-delete functionality

  belongs_to :product
  belongs_to :nu_safety_certificate, class_name: "ResearchSafetyCertificate"

  validates :product, presence: true
  validates :nu_safety_certificate, presence: true
  validates :nu_safety_certificate, uniqueness: { scope: [:deleted_at, :product_id] }

  alias_attribute :certificate, :nu_safety_certificate

end
