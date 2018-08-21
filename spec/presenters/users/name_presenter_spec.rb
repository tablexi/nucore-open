# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::NamePresenter do
  let(:active_user) { build(:user, first_name: "First", last_name: "Lasterson", username: "me@test.com") }
  let(:suspended_user) { build(:user, first_name: "Del", last_name: "Leted", username: "del@test.com", suspended_at: 1.day.ago) }

  describe "defaults" do
    let(:active_name) { described_class.new(active_user) }
    let(:suspended_name) { described_class.new(suspended_user) }

    describe "full_name" do
      it "renders the active user properly" do
        expect(active_name.full_name).to eq("First Lasterson")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.full_name).to eq("Del Leted (SUSPENDED)")
      end
    end

    describe "last_first_name" do
      it "renders the active user properly" do
        expect(active_name.last_first_name).to eq("Lasterson, First")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.last_first_name).to eq("Leted, Del (SUSPENDED)")
      end
    end
  end

  describe "no suspended_label" do
    let(:active_name) { described_class.new(active_user, suspended_label: false) }
    let(:suspended_name) { described_class.new(suspended_user, suspended_label: false) }

    describe "full_name" do
      it "renders the active user properly" do
        expect(active_name.full_name).to eq("First Lasterson")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.full_name).to eq("Del Leted")
      end
    end

    describe "last_first_name" do
      it "renders the active user properly" do
        expect(active_name.last_first_name).to eq("Lasterson, First")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.last_first_name).to eq("Leted, Del")
      end
    end
  end

  describe "with username_label" do
    let(:active_name) { described_class.new(active_user, username_label: true) }
    let(:suspended_name) { described_class.new(suspended_user, username_label: true) }

    describe "full_name" do
      it "renders the active user properly" do
        expect(active_name.full_name).to eq("First Lasterson (me@test.com)")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.full_name).to eq("Del Leted (del@test.com) (SUSPENDED)")
      end
    end

    describe "last_first_name" do
      it "renders the active user properly" do
        expect(active_name.last_first_name).to eq("Lasterson, First (me@test.com)")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.last_first_name).to eq("Leted, Del (del@test.com) (SUSPENDED)")
      end
    end
  end

  describe "with username_label but without suspended_label" do
    let(:active_name) { described_class.new(active_user, username_label: true, suspended_label: false) }
    let(:suspended_name) { described_class.new(suspended_user, username_label: true, suspended_label: false) }

    describe "full_name" do
      it "renders the active user properly" do
        expect(active_name.full_name).to eq("First Lasterson (me@test.com)")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.full_name).to eq("Del Leted (del@test.com)")
      end
    end

    describe "last_first_name" do
      it "renders the active user properly" do
        expect(active_name.last_first_name).to eq("Lasterson, First (me@test.com)")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.last_first_name).to eq("Leted, Del (del@test.com)")
      end
    end
  end
end
