# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogEvent do

  describe "search" do

    let!(:log_1) do
      create(:log_event, loggable_type: "Account",
                         loggable_id: 1, event_type: :create,
                         event_time: 1.month.ago)
    end
    let!(:log_2) do
      create(:log_event, loggable_type: "AccountUser",
                         loggable_id: 2, event_type: :create,
                         event_time: 1.week.ago)
    end
    let!(:log_3) do
      create(:log_event, loggable_type: "User",
                         loggable_id: 3, event_type: :create,
                         event_time: 1.day.ago)
    end

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
      expect(LogEvent.search(events: ["account.create"]).to_a).to eq([log_1])
      expect(LogEvent.search(events: ["account_user.create"]).to_a).to eq([log_2])
      expect(LogEvent.search(events: ["user.create"]).to_a).to eq([log_3])
      expect(LogEvent.search(events: ["user.create", "account_user.create"]).to_a)
        .to eq([log_2, log_3])
    end

    it "whitelists event type" do
      search = LogEventSearcher.new(events: ["user.create", "cheeseburger.create", "user.update"])
      expect(search.events).to eq(["user.create"])
    end

  end

  describe "search by string" do

    let!(:owner) { create(:user, first_name: "Admin", last_name: "Person") }
    let!(:kermit) { create(:user, first_name: "Kermit", last_name: "Frog") }
    let!(:piggy) { create(:user, first_name: "Miss", last_name: "Piggy") }
    let!(:account_007) { create(:account, :with_account_owner, account_number: "007-a1") }
    let!(:account_010) { create(:account, :with_account_owner, account_number: "010-frog1") }
    let!(:au_kermit_007) { create(:account_user, account: account_007, user: kermit, user_role: "Purchaser") }
    let!(:au_piggy_010) { create(:account_user, account: account_010, user: piggy, user_role: "Purchaser") }

    let!(:log_007) { LogEvent.log(account_007, :create, owner, event_time: 1.week.ago) }
    let!(:log_010) { LogEvent.log(account_010, :create, owner, event_time: 1.week.ago) }
    let!(:log_kermit) { LogEvent.log(kermit, :create, owner, event_time: 1.week.ago) }
    let!(:log_piggy) { LogEvent.log(piggy, :create, owner, event_time: 1.week.ago) }
    let!(:log_au_kermit) { LogEvent.log(au_kermit_007, :create, owner, event_time: 1.week.ago) }
    let!(:log_au_piggy) { LogEvent.log(au_piggy_010, :create, owner, event_time: 1.week.ago) }

    it "searches based on account number" do
      expect(LogEvent.search(query: "007").to_a).to eq([log_007, log_au_kermit])
    end

    it "searches based on user name" do
      expect(LogEvent.search(query: "Kermit").to_a).to eq(
        [log_kermit, log_au_kermit])
    end

    it "could find either" do
      expect(LogEvent.search(query: "frog").to_a).to eq(
        [log_010, log_kermit, log_au_kermit, log_au_piggy])
    end

  end

end
