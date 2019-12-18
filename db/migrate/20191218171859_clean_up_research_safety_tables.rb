# frozen_string_literal: true

class CleanUpResearchSafetyTables < ActiveRecord::Migration[5.0]

  def change
    rename_table :nu_safety_certificates, :research_safety_certificates
    rename_index :nu_product_cert_requirements, :index_nu_product_cert_requirements_on_nu_safety_certificate_id, :i_product_cert_req_on_cert_id
    rename_index :nu_product_cert_requirements, :index_nu_product_cert_requirements_on_product_id, :index_nu_product_cert_req_on_product_id
    rename_table :nu_product_cert_requirements, :product_research_safety_certification_requirements
    rename_column :product_research_safety_certification_requirements, :nu_safety_certificate_id, :research_safety_certificate_id
  end

end
