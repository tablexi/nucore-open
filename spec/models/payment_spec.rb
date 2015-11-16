require "rails_helper"

RSpec.describe Payment do
  describe "validations" do
    it { is_expected.to validate_presence_of :source }
    it "does not allow a source that is not included in the list" do
      payment = described_class.new(source: :something_invalid)
      expect(payment).to be_invalid
      expect(payment.errors).to include(:source)
    end
  end
end
