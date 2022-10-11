# frozen_string_literal: true

require "rails_helper"

# NOTE: feature_setting: { active_storage: true }
# does not work as expected because the module
# has class methods that get evaluated on load
RSpec.describe DownloadableFile do

  let(:facility) { create(:setup_facility) }
  let(:item) { FactoryBot.create(:item, facility: facility) }

  let(:file_path) { "#{Rails.root}/spec/files/template1.txt" }
  let(:uploaded_file) { File.open(file_path) }
  let(:stored_file) do
    item.stored_files.create(
      name: "File 1",
      file: uploaded_file,
      file_type: "info",
      creator: create(:user),
    )
  end

  describe "attaching and reading files" do
    context "with a persisted record" do
      it "is persisted" do
        expect(stored_file).to be_persisted
      end

      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq(File.read(file_path))
      end
    end

    context "with a non-persisted record" do
      let(:uploaded_file) { File.open(file_path) }
      let(:stored_file) do
        item.stored_files.build(
          name: "File 1",
          file: uploaded_file,
          file_type: "info",
          creator: create(:user),
        )
      end

      it "is not persisted" do
        expect(stored_file).not_to be_persisted
      end

      it "can read the file content" do
        expect(stored_file.read_attached_file).to eq(File.read(file_path))
      end

      context "with StringIO file" do
        let(:uploaded_file) { StringIO.new("c,s,v") }

        it "can read the file content" do
          expect(stored_file.read_attached_file).to eq("c,s,v")
        end
      end

      context "with test file upload" do
        let(:stored_file) do
          build(
            :stored_file,
            product: item,
            file: Rack::Test::UploadedFile.new(file_path),
            creator: create(:user),
          )
        end

        it "can read the file content" do
          expect(stored_file.read_attached_file).to eq(File.read(file_path))
        end
      end

      context "with no file attached" do
        let(:stored_file) do
          item.stored_files.build(
            name: "File 1",
            file_type: "info",
            creator: create(:user),
          )
        end

        it "returns nil" do
          expect(stored_file.read_attached_file).to eq(nil)
        end
      end
    end
  end

end


