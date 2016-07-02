require "rails_helper"
require_relative "../../support/shared_contexts/setup_sanger_service"

RSpec.describe "Uploading a results file", :js do
  include_context "Setup Sanger Service"

  let!(:purchased_order) { FactoryGirl.create(:purchased_order, product: service, account: account) }
  let!(:purchased_submission) { FactoryGirl.create(:sanger_sequencing_submission, order_detail: purchased_order.order_details.first, sample_count: 3) }

  let!(:batch) { FactoryGirl.create(:sanger_sequencing_batch, submissions: [purchased_submission], facility: facility) }

  let(:facility_staff) { FactoryGirl.create(:user, :staff, facility: facility) }

  # From http://stackoverflow.com/questions/5188240/using-selenium-to-imitate-dragging-a-file-onto-an-upload-element
  def drop_files files, drop_area_id
    js_script = "fileList = Array();"
    Array(files).count.times do |i|
      # Generate a fake input selector
      page.execute_script("if ($('#capybaraUpload#{i}').length == 0) { capybaraUpload#{i} = window.$('<input/>').attr({id: 'capybaraUpload#{i}', type:'file'}).appendTo('body'); }")
      # Attach file to the fake input selector through Capybara
      attach_file("capybaraUpload#{i}", files[i])

      # draggable = find("#capybaraUpload#{i}").first
      draggable = find("input[type=file]")
      droppable = find("##{drop_area_id}")
      draggable.drag_to(droppable)
      # Build up the fake js event
      # js_script = "#{js_script} fileList.push(capybaraUpload#{i}.get(0).files[0]);"
    end


    # Trigger the fake drop event
    # page.execute_script("#{js_script} e = $.Event('drop'); e.originalEvent = {dataTransfer : { files : fileList } }; $('##{drop_area_id}').trigger(e);")
  end

  before do
    login_as facility_staff
    visit facility_sanger_sequencing_admin_batch_path(facility, batch)

    fixture = File.join(SangerSequencing::Engine.root, "spec/support/file_fixtures/test.txt")
    dest = File.join(Rails.root, "tmp", "#{purchased_submission.samples.first.id}_file.txt")
    FileUtils.cp_r(fixture, dest)
    attach_file "[name=qqfile]", dest, visible: false
    # drop_files fixture, "uploader"
    # sleep 3
    click_button "Upload"
    save_and_open_page
  end

  xit "saves a file" do
    sleep(5)
    expect(page).to have_css(".qq-upload-success")
    expect(StoredFile.count).to eq(1)
    expect(StoredFile.last.order_detail).to eq(purchased_submission.order_detail)
  end
end
