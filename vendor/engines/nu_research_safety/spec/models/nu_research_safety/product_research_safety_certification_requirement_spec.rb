# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductResearchSafetyCertificationRequirement, type: :model do
  context "validations" do
    it { is_expected.to validate_presence_of(:product) }
    it { is_expected.to validate_presence_of(:research_safety_certificate) }

    context "with an existing requirement" do
      let!(:product_certification_requirement) { FactoryBot.create(:product_certification_requirement) }
      let(:product) { product_certification_requirement.product }
      let(:certificate) { product_certification_requirement.research_safety_certificate }

      it 'prevents a duplicate requirement for the same product', :aggregate_failures do
        cert_req = product.product_research_safety_certification_requirements.build(research_safety_certificate: certificate)
        expect(cert_req).to be_invalid
        expect(cert_req.errors).to be_added(:research_safety_certificate, :taken)
      end

      it 'does not prevent adding a previously deleted requirement' do
        product_certification_requirement.destroy
        cert_req = product.product_research_safety_certification_requirements.build(research_safety_certificate: certificate)
        expect(cert_req).to be_valid
      end
    end
  end
end
