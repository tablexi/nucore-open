# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductPresenter do

  describe "with_archived_tag" do
    subject(:presenter) { described_class.new(product) }
    describe "is archived" do
      let(:product) { build(:item, name: "Widget", is_archived: true) }

      it "has the inactive tag on it" do
        expect(presenter.with_archived_tag).to eq("Widget (Inactive)")
      end
    end

    describe "is not archived (is active)" do
      let(:product) { build(:item, name: "Widget", is_archived: false) }

      it "does not have the inactive tag on it" do
        expect(presenter.with_archived_tag).to eq("Widget")
      end
    end
  end
end
