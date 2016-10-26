require "rails_helper"

RSpec.describe BulkEmail::Job, type: :model do
  subject(:bulk_email_job) { FactoryGirl.build(:bulk_email_job) }

  it { is_expected.to validate_presence_of(:sender) }
  it { is_expected.to validate_presence_of(:subject) }
  it { is_expected.to serialize(:recipients).as(Array) }
  it { is_expected.to serialize(:search_criteria).as(Hash) }
end
