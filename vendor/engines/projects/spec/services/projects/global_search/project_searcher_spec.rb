require "rails_helper"

RSpec.describe Projects::GlobalSearch::ProjectSearcher do
  let(:facility) { nil }
  let!(:facility_a) { FactoryGirl.create(:facility) }
  let!(:facility_b) { FactoryGirl.create(:facility) }
  let!(:facility_a_projects) { FactoryGirl.create_list(:project, 2, facility: facility_a) }
  let!(:facility_b_projects) { FactoryGirl.create_list(:project, 2, facility: facility_b) }
  let(:query) { nil }
  let(:searcher) { described_class.new(user, facility, query) }
  let(:user) { FactoryGirl.create(:user, :administrator) }

  describe "#results" do
    subject(:results) { searcher.results }

    shared_examples_for "it returns empty results for empty queries" do
      context "when the query is nil" do
        it { is_expected.to be_empty }
      end

      context "when the query is an empty string" do
        let(:query) { "" }
        it { is_expected.to be_empty }
      end

      context "when the query contains only whitespace" do
        let(:query) { " \t \r \n " }
        it { is_expected.to be_empty }
      end

      context "when the query does not match a project name" do
        let(:query) { "not a project" }
        it { is_expected.to be_empty }
      end
    end

    context "when in a facility context" do
      let(:facility) { facility_a }

      it_behaves_like "it returns empty results for empty queries"

      context "when the query matches a project name" do
        context "that belongs to the facility" do
          let(:query) { facility_a_projects.first.name }
          it { is_expected.to eq [facility_a_projects.first] }
        end

        context "that belongs to another facility" do
          let(:query) { facility_b_projects.first.name }
          it { is_expected.to be_empty }
        end
      end
    end

    shared_examples_for "it's not in a single facility context" do
      it_behaves_like "it returns empty results for empty queries"

      context "when the query matches a project name" do
        let(:query) { facility_b_projects.last.name }
        it { is_expected.to eq [facility_b_projects.last ] }
      end
    end

    context "when in a global context" do
      it_behaves_like "it's not in a single facility context"
    end

    context "when in a cross-facility (ALL) context" do
      let(:facility) { Facility.cross_facility }

      it_behaves_like "it's not in a single facility context"
    end
  end

  describe "#template" do
    it { expect(searcher.template).to eq("projects") }
  end
end
