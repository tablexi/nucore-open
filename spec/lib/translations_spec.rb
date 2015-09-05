require "rails_helper"

RSpec.describe 'Translation loading' do
  it "loads override/*.yml files" do
    expect(I18n.t("testing.locale_loading")).to start_with("This is here")
  end

  it "gives override/*.yml precedence over the root files" do
    expect(I18n.t("testing.overriding")).to start_with("This overrides")
  end
end
