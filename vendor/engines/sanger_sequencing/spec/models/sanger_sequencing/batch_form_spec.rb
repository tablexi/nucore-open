require "rails_helper"

RSpec.describe SangerSequencing::BatchForm do
  let(:submission) { FactoryGirl.create(:sanger_sequencing_submission, sample_count: 2) }
  let(:submission2) { FactoryGirl.create(:sanger_sequencing_submission, sample_count: 3) }

  describe "new" do
    let(:form) { described_class.new }
    before { form.assign_attributes(params) }

    describe "blank" do
      let(:params) { { submission_ids: "" } }

      it "does not allow no submissions" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submission_ids, :blank)
      end
    end

    describe "with one submission" do
      describe "with all the samples" do
        let(:params) do
          { submission_ids: "#{submission.id}",
            well_plate_data: { "0" => { "A01" => submission.samples.first.id,
                                        "B02" => submission.samples.second.id }
                         }
          }
        end

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end

    describe "missing a sample" do
      let(:params) do
        { submission_ids: "#{submission.id}",
          well_plate_data: { "0" => { "A01" => submission.samples.first.id } }
        }
      end

      it "is invalid" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submitted_sample_ids, :must_match_submissions)
      end
    end

    describe "with a sample from the second submission" do
      let(:params) do
        { submission_ids: "#{submission.id}",
          well_plate_data: { "0" => { "A01" => submission.samples.first.id,
                                      "B01" => submission2.samples.first.id } }
        }
      end

      it "is invalid" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submitted_sample_ids, :must_match_submissions)
      end
    end

    describe "adding a submission that is already part of a batch" do
      let!(:batch) { SangerSequencing::Batch.create(submissions: [submission]) }
      let(:params) do
        { submission_ids: submission.id.to_s }
      end

      it "is not valid" do
        expect(form).to be_invalid
        expect(form.errors).to be_added(:submission_ids, :submission_part_of_other_batch, id: submission.id)
      end
    end

  end
end
