# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearch::ProductSearcher do

  subject(:results) { searcher.results }

  let(:facility) { nil }
  let(:searcher) { described_class.new(user, facility, query) }
  let(:user) { create(:user) }
  let(:item) { Item.find_by!(url_name: "lsc-andor") }
  before(:context) do
    facility = create(:facility)
    item = build(:item, url_name: "lsc-andor", name: "LSC Andor Spinning Disk", facility: facility)
    item.save(validate: false)
  end

  after(:context) do
    Item.delete_all
    Facility.delete_all
  end

  describe "#results" do
    context "when the query is nil" do
      let(:query) { nil }
      it { is_expected.to be_empty }
    end

    context "when the query is whitespace only" do
      let(:query) { "   " }
      it { is_expected.to be_empty }
    end

    context "when the query matches no products" do
      let(:query) { "gobbledy gook" }
      it { is_expected.to be_empty }
    end

    context "when the query case does not match the db case" do
      let(:query) { "lsc" }
      it {
        is_expected.to contain_exactly(item)
      }
    end

    context "when the query matches results the user doesn't have permissions to view" do
      let(:query) { "lsc" }

      before do
        item.is_hidden = true
        item.save(validate: false)
      end

      it { is_expected.to be_empty }
    end

    context "when it matches multiple words, but not exactly" do
      let!(:item2) { create(:setup_item, name: "LSC Nikon A1RSi") }
      let(:query) { "lsc spinning disk" }

      it "matches both products with the one matching more words first" do
        is_expected.to eq([item, item2])
      end
    end

    context "when query matches a hidden product that the user has permissions to view" do
      let(:user) { create(:user, :staff, facility: item.facility) }
      let(:query) { "lsc" }

      before do
        item.is_hidden = true
        item.save(validate: false)
      end

      it { is_expected.to contain_exactly(item) }
    end

    context "when query matches a product that belongs to an inactive facility" do
      let(:inactive_facility) { create(:facility, is_active: false) }
      let(:query) { "lsc" }

      before do
        item.facility = inactive_facility
        item.save(validate: false)
      end

      it { is_expected.to be_empty }
    end

  end

end
