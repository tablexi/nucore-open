# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::NamePresenter do
  let(:active_user) { build(:user, first_name: "First", last_name: "Lasterson", username: "me@test.com") }
  let(:suspended_user) { build(:user, first_name: "Del", last_name: "Leted", username: "del@test.com", suspended_at: 1.day.ago) }
  let(:expired_user) { build(:user, first_name: "Exp", last_name: "Ired", username: "expired@test.com", expired_at: 1.day.ago) }
  let(:expired_and_suspended_user) { build(:user, first_name: "Exp", last_name: "Susp", username: "both@test.com", expired_at: 1.day.ago, suspended_at: 1.day.ago) }

  describe "defaults" do
    let(:active_name) { described_class.new(active_user) }
    let(:suspended_name) { described_class.new(suspended_user) }
    let(:expired_name) { described_class.new(expired_user) }
    let(:expired_and_suspended_name) { described_class.new(expired_and_suspended_user) }

    describe "full_name" do
      it "renders the active user properly" do
        expect(active_name.full_name).to eq("First Lasterson")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.full_name).to eq("Del Leted (SUSPENDED)")
      end

      it "renders the expired user with a tag" do
        expect(expired_name.full_name).to eq("Exp Ired (EXPIRED)")
      end

      it "renders the suspended and expired with the suspended tag" do
        expect(expired_and_suspended_name.full_name).to eq("Exp Susp (SUSPENDED)")
      end
    end

    describe "last_first_name" do
      it "renders the active user properly" do
        expect(active_name.last_first_name).to eq("Lasterson, First")
      end

      it "renders the suspended user with a tag" do
        expect(suspended_name.last_first_name).to eq("Leted, Del (SUSPENDED)")
      end

      it "renders the expired user with a tag" do
        expect(expired_name.last_first_name).to eq("Ired, Exp (EXPIRED)")
      end

      it "renders the suspended and expired with the suspended tag" do
        expect(expired_and_suspended_name.last_first_name).to eq("Susp, Exp (SUSPENDED)")
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
