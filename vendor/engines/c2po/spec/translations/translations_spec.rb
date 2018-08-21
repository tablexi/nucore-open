# frozen_string_literal: true

require "rails_helper"

RSpec.describe "C2PO Translation loading" do
  it "loads the translation from the engine" do
    expect(I18n.t("views.c2po.facilities.facility_fields.labels.accepts_po")).to eq("Accept Purchase Orders?")
  end
end
