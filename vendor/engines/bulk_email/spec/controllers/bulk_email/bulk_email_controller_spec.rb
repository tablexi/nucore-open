require "rails_helper"
require "controller_spec_helper"

RSpec.describe BulkEmail::BulkEmailController do
  render_views

  let(:facility) { facility_account.facility }
  let(:facility_account) { FactoryGirl.create(:facility_account) }
  let!(:instrument) { FactoryGirl.create(:instrument, facility: facility, facility_account_id: facility_account.id) }
  let!(:item) { FactoryGirl.create(:item, facility: facility, facility_account_id: facility_account.id) }
  let!(:restricted_item) { FactoryGirl.create(:item, facility: facility, facility_account_id: facility_account.id, requires_approval: true) }
  let!(:service) { FactoryGirl.create(:service, facility: facility, facility_account_id: facility_account.id) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility # controller_spec_helper requires @authable
    @params = { facility_id: facility.url_name }
  end

  context "search" do
    before :each do
      @action = "search"
      @method = :post
      @params.merge!(user_types: user_types)
    end

    context "testing authorization" do
      let(:user_types) { nil }

      it_should_require_login
      it_should_allow_managers_only {}
    end

    context "authorized" do
      before { maybe_grant_always_sign_in :director }

      context "when the at least one user_type is set" do
        let(:user_types) { %i(customers) }

        before { do_request }

        it { expect(assigns[:users]).not_to be_nil }
      end

      context "when no user_types are set" do
        let(:user_types) { [] }

        before { do_request }

        it { expect(assigns[:users]).to be_empty }
      end

      context "parameter settings" do
        let(:user_types) { %i(customers) }

        before(:each) do
          do_request
          expect(response).to be_success
        end

        it "sets products, in order" do
          expect(assigns[:products])
            .to eq([item, service, instrument, restricted_item].sort)
        end

        it "sets user_types, in order" do
          expect(assigns[:user_types].keys)
            .to eq(%i(customers authorized_users account_owners))
        end

        it "sets the facility_id as the id, not url_name" do
          expect(assigns[:search_fields][:facility_id]).to eq(facility.id)
        end

        context "when where are no restricted instruments" do
          before { restricted_item.destroy }

          it "does not include authorized_users as a user_type" do
            do_request
            expect(assigns[:user_types]).not_to be_include(:authorized_users)
          end
        end
      end

      context "when there is a hidden product" do
        let(:user_types) { %i(customers) }

        let!(:hidden_product) { FactoryGirl.create(:item, :hidden, facility: facility, facility_account_id: facility_account.id) }

        it "includes the hidden product" do
          do_request
          expect(response).to be_success
          expect(assigns[:products]).to be_include(hidden_product)
        end
      end

      context "when there is an archived product" do
        let(:user_types) { %i(customers) }

        let!(:archived_product) { FactoryGirl.create(:item, :archived, facility: facility, facility_account_id: facility_account.id) }

        it "does not load the archived product" do
          do_request
          expect(response).to be_success
          expect(assigns[:products]).not_to be_include(archived_product)
        end
      end
    end

    context "when rendering as csv" do
      let(:user_types) { %i(customers) }

      before(:each) do
        maybe_grant_always_sign_in :director
        @params.merge!(format: "csv")
        do_request
      end

      it "sets the filename" do
        expect(response.headers["Content-Disposition"])
          .to eq('attachment; filename="bulk_email_customers.csv"')
      end
    end
  end
end
