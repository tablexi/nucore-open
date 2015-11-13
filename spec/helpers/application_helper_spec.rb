require "rails_helper"
require 'controller_spec_helper'

RSpec.describe ApplicationHelper do
  describe "#menu_facilities" do
    before(:all) do
      create_users
    end

    before(:each) do
      UserRole.grant(user, UserRole::FACILITY_DIRECTOR, facilities.first)
      UserRole.grant(user, UserRole::FACILITY_STAFF, facilities.second)
    end

    let!(:facilities) { create_list(:facility, 3) }

    def session_user
      user
    end

    shared_examples_for "it returns only facilities with a role" do
      it { expect(menu_facilities).to match_array(facilities.first(2)) }
    end

    context "when the user is a guest" do
      let(:user) { @guest }
      it_behaves_like "it returns only facilities with a role"
    end

    context "when the user is a global admin" do
      let(:user) { @admin }
      it_behaves_like "it returns only facilities with a role"
    end

    context "when the user is a billing_admin" do
      let(:user) { @billing_admin }
      it_behaves_like "it returns only facilities with a role"
    end
  end

  describe "#order_detail_description_as_(html|text)" do
    let(:order_detail) { build_stubbed(:order_detail) }
    let(:product) { build_stubbed(:product, name: ">& Product <") }

    before { allow(order_detail).to receive(:product).and_return(product) }

    context "when not part of a bundle" do
      context "as html" do
        subject { order_detail_description_as_html(order_detail) }

        it { expect(subject).to be_html_safe }
        it { expect(subject).to eq("&gt;&amp; Product &lt;") }
      end

      context "as text" do
        subject { order_detail_description_as_text(order_detail) }

        it { expect(subject).to be_html_safe }
        it { expect(subject).to eq(">& Product <") }
      end
    end

    context "when part of a bundle" do
      let(:bundle) { build_stubbed(:bundle, name: ">& Bundle <") }
      before { allow(order_detail).to receive(:bundle).and_return(bundle) }

      context "as html" do
        subject { order_detail_description_as_html(order_detail) }

        it { expect(subject).to be_html_safe }
        it { expect(subject).to eq("&gt;&amp; Bundle &lt; &mdash; &gt;&amp; Product &lt;") }
      end

      context "as text" do
        subject { order_detail_description_as_text(order_detail) }

        it { expect(subject).to be_html_safe }
        it { expect(subject).to eq(">& Bundle < -- >& Product <") }
      end
    end
  end
end
