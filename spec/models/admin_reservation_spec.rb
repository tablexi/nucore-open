# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminReservation do
  it "sets billable_minutes to nil before saving" do
    expect(subject).to receive(:billable_minutes=).with(nil)
    subject.run_callbacks(:save) { false }
  end
end
