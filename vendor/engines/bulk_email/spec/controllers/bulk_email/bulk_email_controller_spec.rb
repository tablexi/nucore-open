require "rails_helper"
require "controller_spec_helper"

RSpec.describe BulkEmail::BulkEmailController do
  render_views

  let(:facility) { facility_account.facility }
  let(:facility_account) { FactoryGirl.create(:facility_account) }
  let!(:instrument) { FactoryGirl.create(:instrument, facility_account: facility_account) }
  let!(:item) { FactoryGirl.create(:item, facility_account: facility_account) }
  let!(:restricted_item) { FactoryGirl.create(:item, facility_account: facility_account, requires_approval: true) }
  let!(:service) { FactoryGirl.create(:service, facility_account: facility_account) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility # controller_spec_helper requires @authable
    @params = { facility_id: facility.url_name }
  end

  describe "POST #search" do
    before :each do
      @action = "search"
      @method = :post
      @params.merge!(bulk_email: { user_types: user_types })
    end

    context "testing authorization" do
      let(:user_types) { [] }

      it_should_require_login
      it_should_allow_managers_and_senior_staff_only {}
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

        it { expect(assigns[:users]).to be_blank }
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
            expect(assigns[:user_types]).not_to include(:authorized_users)
          end
        end
      end

      context "when there is a hidden product" do
        let(:user_types) { %i(customers) }

        let!(:hidden_product) do
          FactoryGirl.create(:item, :hidden, facility_account: facility_account)
        end

        it "includes the hidden product" do
          do_request
          expect(response).to be_success
          expect(assigns[:products]).to include(hidden_product)
        end
      end

      context "when there is an archived product" do
        let(:user_types) { %i(customers) }

        let!(:archived_product) do
          FactoryGirl.create(:item, :archived, facility_account: facility_account)
        end

        it "does not load the archived product" do
          do_request
          expect(response).to be_success
          expect(assigns[:products]).not_to include(archived_product)
        end
      end
    end
  end

  describe "POST #create" do
    let(:recipients) { FactoryGirl.create_list(:user, 3) }
    let(:expected_csv_content) { csv_header + "\n" + expected_csv_body + "\n" }
    let(:csv_header) { "Name,Username,Email" }
    let(:expected_csv_body) do
      recipients.map do |user|
        [user.full_name, user.username, user.email].join(",")
      end.join("\n")
    end

    before(:each) do
      @action = "create"
      @method = :post
      @params[:format] = :csv
      @params[:recipient_ids] = recipients.map(&:id)

      maybe_grant_always_sign_in :director
      do_request
    end

    it "generates the expected CSV" do
      expect(response.headers["Content-Disposition"])
        .to eq('attachment; filename="bulk_email_recipients.csv"')
      expect(response.body).to eq(expected_csv_content)
    end
  end

  describe "POST #deliver" do
    let(:recipients) { FactoryGirl.create_list(:user, 3) }
    let(:custom_message) { "Custom message" }
    let(:return_path) { nil }

    before(:each) do
      @action = "deliver"
      @method = :post
      @params[:bulk_email_delivery_form] = {
        custom_subject: custom_subject,
        custom_message: custom_message,
        recipient_ids: recipients.map(&:id),
        search_criteria: { this: "is", a: "test" }.to_json,
      }
      @params[:return_path] = return_path if return_path.present?

      sign_in @admin
      do_request
    end

    context "when the form is valid" do
      let(:custom_subject) { "Custom subject" }

      context "when no return_path param specified" do
        it "submits successfully" do
          is_expected.to redirect_to(facility_bulk_email_path)
          expect(flash[:notice]).to include("3 email messages queued")
        end
      end

      context "with a routable return_path param" do
        let(:return_path) { facility_instruments_path(facility) }

        it "redirects to the path specified in the param" do
          is_expected.to redirect_to(return_path)
        end
      end

      context "with a return_path param set to a full URL" do
        let(:return_path) { "http://example.net/" }

        it "falls back to redirecting to the bulk email path" do
          is_expected.to redirect_to(facility_bulk_email_path)
        end
      end

      context "with a non-routable return_path param" do
        let(:return_path) { "a bad return path value" }

        it "falls back to redirecting to the bulk email path" do
          is_expected.to redirect_to(facility_bulk_email_path)
        end
      end
    end

    context "when the form is invalid" do
      let(:custom_subject) { "" }

      it "redisplays the form with errors" do
        is_expected.to render_template(:create)
        expect(assigns[:delivery_form].errors[:custom_subject])
          .to include("can't be blank")
      end
    end
  end
end
