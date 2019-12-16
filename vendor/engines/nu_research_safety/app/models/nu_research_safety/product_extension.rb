# frozen_string_literal: true

module NuResearchSafety

  module ProductExtension

    extend ActiveSupport::Concern

    included do
      has_many :product_research_safety_certification_requirements
      has_many :nu_safety_certificates, through: :product_research_safety_certification_requirements

      alias_attribute :certificates, :nu_safety_certificates
    end

  end

end
