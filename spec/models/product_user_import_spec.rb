# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductUserImport do

  let(:admin) { create(:user, :administrator) }
  let(:product) { create(:setup_item) }
  let(:file) { StringIO.new(body) }
  let(:body) do
    <<~CSV
      Username
      admin
      director
      user123
    CSV
  end

  subject(:import) do
    ProductUserImport.new(
      creator: admin,
      file: file,
      product: product
    )
  end

  context "validations" do
    it { is_expected.to belong_to :creator }
    it { is_expected.to validate_presence_of :file }
    it { is_expected.to validate_presence_of :creator }
  end

  describe "#process_upload!" do
    context "when no Username column exists" do
      let(:body) do
        <<~CSV
          Wrong Column Name
          admin
          director
          user123
        CSV
      end

      before { import.process_upload! }

      it { is_expected.to be_failed }
      it { is_expected.not_to be_persisted }

      it "includes a failure message" do
        expect(import.failures).to include("Uploaded CSV file must include a Username Column.  Please try again.")
      end
    end
  end
end
