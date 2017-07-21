require "rails_helper"

RSpec.describe LogEvent do

  let!(:log_1) do
    create(:log_event, loggable_type: "Account",
                       loggable_id: 1, event_type: :create, event_time: 1.month.ago)
  end
  let!(:log_2) do
    create(:log_event, loggable_type: "AccountUser",
                       loggable_id: 2, event_type: :create, event_time: 1.week.ago)
  end
  let!(:log_3) do
    create(:log_event, loggable_type: "User",
                       loggable_id: 3, event_type: :create, event_time: 1.day.ago)
  end

  describe "search" do

    it "finds all the items without a date filter" do
      expect(LogEvent.search.to_a).to eq([log_1, log_2, log_3])
    end

    it "works with a date filter" do
      expect(LogEvent.search(start_date: 2.weeks.ago, end_date: 2.days.ago).to_a)
        .to eq([log_2])
    end

    it "works with a flipped date filter" do
      expect(LogEvent.search(start_date: 2.days.ago, end_date: 2.weeks.ago).to_a)
        .to eq([log_2])
    end

    it "works without a start_date" do
      expect(LogEvent.search(end_date: 2.days.ago).to_a)
        .to eq([log_1, log_2])
    end

    it "works without an end date" do
      expect(LogEvent.search(start_date: 2.weeks.ago).to_a)
        .to eq([log_2, log_3])
    end

    it "filters on event type" do
      expect(LogEvent.search(events: ["account__create"]).to_a).to eq([log_1])
      expect(LogEvent.search(events: ["account_user__create"]).to_a).to eq([log_2])
      expect(LogEvent.search(events: ["user__create"]).to_a).to eq([log_3])
      expect(LogEvent.search(events: ["user__create", "account_user__create"]).to_a)
        .to eq([log_2, log_3])
    end

  end

end
