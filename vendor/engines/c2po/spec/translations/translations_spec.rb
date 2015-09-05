require "rails_helper"

RSpec.describe "C2PO Translation loading" do
  it "loads the translation from the engine" do
    expect(I18n.t("facilities.facility_fields.accepts_po")).to eq("Accept Purchase Orders?")
  end
end
