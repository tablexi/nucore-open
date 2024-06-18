# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects search" do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  let!(:active_project) { create(:project, facility:) }
  let!(:inactive_project) { create(:project, :inactive, facility:) }

  before do
    login_as facility_administrator

    visit facility_projects_path(facility)
  end

  describe "Active filter" do
    context "by default" do
      it "shows only active projects for current facility" do
        expect(page).to have_content(active_project.name)
        expect(page).to have_content(cross_core_project.name)
        expect(page).not_to have_content(cross_core_project2.name)
        expect(page).not_to have_content(cross_core_project3.name)
        expect(page).not_to have_content(inactive_project.name)
      end
    end

    context "when Active is selected" do
      before do
        select "Active", from: "Active/Inactive"
        click_button "Filter"
      end

      it "shows only active projects for current facility" do
        expect(page).to have_content(active_project.name)
        expect(page).to have_content(cross_core_project.name)
        expect(page).not_to have_content(cross_core_project2.name)
        expect(page).not_to have_content(cross_core_project3.name)
        expect(page).not_to have_content(inactive_project.name)
      end
    end

    context "when Inactive is selected" do
      before do
        select "Inactive", from: "Active/Inactive"
        click_button "Filter"
      end

      it "shows only inactive projects for current facility" do
        expect(page).not_to have_content(active_project.name)
        expect(page).not_to have_content(cross_core_project.name)
        expect(page).not_to have_content(cross_core_project2.name)
        expect(page).not_to have_content(cross_core_project3.name)
        expect(page).to have_content(inactive_project.name)
      end
    end
  end
end
