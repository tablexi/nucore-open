# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearch::ProductSearcher do

  subject(:results) { searcher.results }

  let(:facility) { Facility.find_by(url_name: "facility") }
  let(:searcher) { described_class.new(user, facility, query) }
  let(:user) { create(:user) }
  let(:item) { Item.find_by!(url_name: "lsc-andor") }

  # Both MySql and Oracle do not update their full-text indexes until a COMMIT. RSpec
  # runs each example inside of a transaction, so if we query the full text index,
  # we'll get no results. These objects are created outside of the transaction, so
  # we must be very careful that they are cleaned up afterwards.
  before(:context) do
    # Do not use factories to ensure we don't end up with any zombie associations
    facility = Facility.new(name: "name", abbreviation: "EF", url_name: "facility", is_active: true, short_description: "abc", journal_mask: "C01")
    facility.save(validate: false)
    item = Item.new(url_name: "lsc-andor", name: "LSC Andor Spinning Disk", facility: facility)
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
      before(:context) do
        facility = Facility.find_by(url_name: "facility")
        Item.new(name: "LSC Nikon A1RSi", facility: facility, url_name: "lsc_nikon").save(validate: false)
      end
      let(:item2) { Item.find_by(url_name: "lsc_nikon") }
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
