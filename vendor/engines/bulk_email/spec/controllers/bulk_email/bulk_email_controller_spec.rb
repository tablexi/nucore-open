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
      @params.merge!(search_type: :customers)
    end
    it_should_require_login
    it_should_allow_managers_only {}

    context "authorized" do
      before { maybe_grant_always_sign_in :director }

      context "when the search_type is set" do
        before { do_request }

        it { expect(assigns[:users]).not_to be_nil }
      end

      context "when search_type is not set" do
        before(:each) do
          @params.delete(:search_type)
          do_request
        end

        it { expect(assigns[:users]).to be_nil }
      end

      context "parameter settings" do
        before(:each) do
          do_request
          expect(response).to be_success
        end

        it "sets products, in order" do
          expect(assigns[:products])
            .to eq([item, service, instrument, restricted_item].sort)
        end

        it "sets search_types, in order" do
          expect(assigns[:search_types].keys)
            .to eq(%i(customers account_owners customers_and_account_owners authorized_users))
        end

        it "sets the facility_id as the id, not url_name" do
          expect(assigns[:search_fields][:facility_id]).to eq(facility.id)
        end

        context "when where are no restricted instruments" do
          before { restricted_item.destroy }

          it "does not include authorized_users as a search_type" do
            do_request
            expect(assigns[:search_types]).not_to be_include(:authorized_users)
          end
        end
      end

      context "when there is a hidden product" do
        let!(:hidden_product) { FactoryGirl.create(:item, :hidden, facility: facility, facility_account_id: facility_account.id) }

        it "includes the hidden product" do
          do_request
          expect(response).to be_success
          expect(assigns[:products]).to be_include(hidden_product)
        end
      end

      context "when there is an archived product" do
        let!(:archived_product) { FactoryGirl.create(:item, :archived, facility: facility, facility_account_id: facility_account.id) }

        it "does not load the archived product" do
          do_request
          expect(response).to be_success
          expect(assigns[:products]).not_to be_include(archived_product)
        end
      end
    end

    context "pagination" do
      before { maybe_grant_always_sign_in :director }

      context "when rendering as html" do
        before { do_request }

        it "paginates the recipient list" do
          expect(assigns[:users]).to be_respond_to(:per_page)
        end
      end

      context "when rendering as csv" do
        before { @params.merge!(format: "csv") }

        it "does not paginate the recipient list" do
          do_request
          expect(assigns[:users]).not_to be_respond_to(:per_page)
        end

        it "sets the filename" do
          do_request
          expect(response.headers["Content-Disposition"])
            .to eq('attachment; filename="bulk_email_customers.csv"')
        end
      end
    end
  end
end
