# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility list tile", feature_setting: { facility_tile_list: true } do
  if SettingsHelper.feature_on?(:active_storage)
    Facility.include DownloadableFiles::Image

    let(:admin_user) { create(:user, :administrator) }
    let(:facility) { create(:facility, :with_image) }

    it "shows image on home page" do
      facility
      visit facilities_path
      save_and_open_page

      expect(page).to have_selector(".tile-image")
    end

    context "image manpulation" do
      before do
        login_as admin_user
        visit edit_facility_path(facility)
      end

      context "with image attached" do
        it "can remove image" do
          check "Remove image"
          click_on "Save"

          expect(page).not_to have_selector(".tile-image")
        end

        it "can replace image" do
          find("#facility_file").set("#{Rails.root}/spec/files/frontier.jpg")
          click_on "Save"
          image = find(".tile-image")

          expect(image[:src]).to have_content "frontier.jpg"
        end
      end

      context "with no image attached" do
        let(:facility) { create(:facility) }

        it "can add an image" do
          expect(page).not_to have_selector(".tile-image")

          find("#facility_file").set("#{Rails.root}/spec/files/cern.jpeg")
          click_on "Save"
          image = find(".tile-image")

          expect(image[:src]).to have_content "cern.jpeg"
        end
      end
    end

  end
end
