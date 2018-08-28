# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::Job, type: :model do
  subject(:bulk_email_job) { FactoryBot.build(:bulk_email_job) }

  it { is_expected.to belong_to(:facility) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:subject) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to serialize(:recipients).as(Array) }
  it { is_expected.to serialize(:search_criteria).as(Hash) }
end
