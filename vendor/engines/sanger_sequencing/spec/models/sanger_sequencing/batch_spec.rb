require "rails_helper"

RSpec.describe SangerSequencing::Batch do
  let(:batch) { described_class.new }
  let(:submission) { FactoryGirl.create(:sanger_sequencing_submission) }
  let(:samples) { FactoryGirl.create_list(:sanger_sequencing_sample, 4, submission: submission) }

  let(:well_plates_raw) do
    [{
      "A01" => "reserved",
      "B01" => samples[0].id,
      "C01" => samples[1].id,
     },
     {
      "A01" => "reserved",
      "B01" => samples[2].id,
      "C01" => samples[3].id,
    }]
  end

  describe "#well_plates=" do
    before do
      batch.well_plates_raw = well_plates_raw
      batch.save!
      batch.reload
    end

    it "has two well plates" do
      expect(batch.well_plates.length).to eq(2)
    end

    describe "the first well plate" do
      let(:well_plate) { batch.well_plates.first }

      it "the sample at A01 is reserved" do
        expect(well_plate["A01"].customer_sample_id).to eq("Control")
      end

      it "the sample at B01 is the first sample" do
        expect(well_plate["B01"]).to eq(samples.first)
      end
    end
  end

  describe "invalid assignment" do
    it "is invalid if not an array" do
      batch.well_plates_raw = { testing: true }
      expect(batch).to be_invalid
    end

    it "is invalid if the hash has an invalid key" do
      batch.well_plates_raw = [{ "RANDOM" => 3 }]
      expect(batch).to be_invalid
    end

    it "is invalid if the value is something random" do
      batch.well_plates_raw = [{ "A01" => "randmon" }]
      expect(batch).to be_invalid
    end
  end
end
