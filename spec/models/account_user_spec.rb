# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountUser do

  context "when creating through Account" do
    subject(:account) { build(:nufs_account, :with_account_owner) }

    it { is_expected.to be_valid }
  end

  context "with a valid user_role" do
    described_class.user_roles.each do |role|
      context role do
        subject { build(:account_user, user_role: role) }

        it { is_expected.to be_valid }
      end
    end
  end

  context "with a blank user_role" do
    subject(:account_user) { build(:account_user, user_role: nil) }

    it "is invalid" do
      is_expected.not_to be_valid
      expect(account_user.errors[:user_role])
        .to include(a_string_matching("invalid"))
    end
  end

  context "with an invalid user_role" do
    subject(:account_user) { build(:account_user, user_role: "Not A Role") }

    it "is invalid" do
      is_expected.not_to be_valid
      expect(account_user.errors[:user_role])
        .to include(a_string_matching("invalid"))
    end
  end

  context "when a user has an active role for an account" do
    let(:account) { create(:nufs_account, :with_account_owner, owner: user) }
    let(:user) { create(:user) }

    context "when creating another role for the user for the account" do
      subject(:account_user) do
        build(:account_user, :purchaser, account: account, user: user)
      end

      it "is invalid" do
        is_expected.not_to be_valid
        expect(account_user.errors[:user_id])
          .to include(a_string_matching("already a member"))
      end
    end
  end

  context "when a user has inactive (deleted) roles for an account" do
    let(:account) { create(:nufs_account, :with_account_owner) }
    let(:user) { create(:user) }

    before(:each) do
      create(:account_user, :purchaser, :inactive, account: account, user: user)
    end

    context "when creating an identical active role" do
      subject(:account_user) do
        build(:account_user, :purchaser, account: account, user: user)
      end

      it { is_expected.to be_valid }
    end
  end

  context "when an account has an active owner" do
    let!(:account) { create(:nufs_account, :with_account_owner) }

    context "when attempting to add another owner" do
      subject(:account_user) do
        build(:account_user, :owner, account: account, user: user)
      end
      let(:user) { create(:user) }

      it "is invalid" do
        is_expected.not_to be_valid
        expect(account_user.errors[:user_role])
          .to include(a_string_matching("already been taken"))
      end
    end
  end

  describe ".selectable_user_roles" do
    let(:facility) { create(:facility) }

    context "when supplying a user who will grant the role" do
      context "who is a facility director (manager)" do
        let(:user) { create(:user, :facility_director, facility: facility) }

        context "and a facility" do
          subject(:roles) { described_class.selectable_user_roles(user, facility) }

          it { is_expected.to include(AccountUser::ACCOUNT_OWNER) }
        end

        context "but no facility" do
          subject(:roles) { described_class.selectable_user_roles(user) }

          it { is_expected.not_to include(AccountUser::ACCOUNT_OWNER) }
        end
      end

      context "who is an account manager" do
        subject(:roles) do
          described_class.selectable_user_roles(user, Facility.cross_facility)
        end
        let(:user) { create(:user, :account_manager) }

        it { is_expected.to include(AccountUser::ACCOUNT_OWNER) }
      end
    end

    context "when not supplying a user" do
      context "but supplying a facility" do
        subject(:roles) { described_class.selectable_user_roles(nil, facility) }

        it { is_expected.not_to include(AccountUser::ACCOUNT_OWNER) }
      end

      context "or a facility" do
        subject(:roles) { described_class.selectable_user_roles }

        it { is_expected.not_to include(AccountUser::ACCOUNT_OWNER) }
      end
    end
  end
end
