require "spec_helper"
require "controller_spec_helper"

def fixture_file(filename)
  ActionDispatch::TestProcess.fixture_file_upload(
    "#{Rails.root}/spec/files/order_imports/#{filename}",
    "text/csv",
  )
end

describe OrderImportsController do
  let(:facility) { create(:facility) }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = facility
    @params = { facility_id: facility.url_name }
  end

  shared_examples_for "it imported no orders" do
    let(:import_id) { assigns(:order_import).id }
    let(:orders) { Order.where(order_import_id: import_id) }

    it "imported no orders" do
      expect(orders).to be_empty
    end

    it "flashes an import failure message" do
      expect(flash[:error]).to match /\bimport failed\b/
    end
  end

  context "starting an import" do
    before :each do
      @action = :new
      @method = :get
    end

    it_should_allow_operators_only do
      expect(assigns :order_import).to be_new_record
      should render_template "new"
    end
  end

  context "importing orders" do
    before :each do
      @action = :create
      @method = :post
      @params.merge!(
        order_import: {
          upload_file: upload_file,
          fail_on_error: fail_on_error,
          send_receipts: send_receipts,
        }
      )
    end

    context "when the file is blank" do
      let(:upload_file) { fixture_file("blank.csv") }
      let(:fail_on_error) { false }
      let(:send_receipts) { false }

      it_should_allow_operators_only do
        flash[:error].should be_blank
        flash[:notice].should be_present
        should render_template "show"
      end

      context "when a director is signed in" do
        before(:each) { maybe_grant_always_sign_in :director }

        it "creates one OrderImport record" do
          expect { do_request }.to change(OrderImport, :count).from(0).to(1)
        end

        it "creates one StoredFile record" do
          expect { do_request }.to change(StoredFile, :count).from(0).to(1)
        end
      end
    end

    context "when the file has errors" do
      let(:facility_account) do
        facility.facility_accounts.create!(attributes_for :facility_account)
      end
      let(:guest) { @guest }
      let(:guest_attributes) { account_users_attributes_hash(user: guest) }
      let(:guest2) { create(:user, username: "guest2") }
      let(:guest2_attributes) do
        account_users_attributes_hash(
          user: guest2,
          created_by: guest,
          user_role: "Purchaser",
        )
      end
      let(:item) { facility.items.create!(item_attributes) }
      let(:item_attributes) do
        attributes_for(:item,
          facility_account_id: facility_account.id,
          name: "Example Item",
        )
      end
      let(:price_group) do
        facility.price_groups.create!(attributes_for(:price_group))
      end
      let(:send_receipts) { true }
      let(:service) { facility.services.create!(service_attributes) }
      let(:service_attributes) do
        attributes_for(:service,
          facility_account_id: facility_account.id,
          name: "Example Service",
        )
      end
      let(:user_attributes) { guest_attributes + guest2_attributes }

      before :each do
        grant_role(@director, facility)

        create(:user_price_group_member, user: guest, price_group: price_group)
        item.item_price_policies.create!(attributes_for(:item_price_policy, price_group_id: price_group.id))
        service.service_price_policies.create!(attributes_for(:service_price_policy, price_group_id: price_group.id))

        create(:user_price_group_member, user: guest2, price_group: price_group)
        create(:nufs_account,
          description: "dummy account",
          account_number: "111-2222222-33333333-01",
          account_users_attributes: user_attributes,
        )

        maybe_grant_always_sign_in :director
      end

      context "save nothing mode" do
        let(:fail_on_error) { true }

        context "the first order detail fails" do
          let(:upload_file) { fixture_file("first_od_error.csv") }

          before(:each) { do_request }

          it "flashes import statistics" do
            expect(flash[:error]).to match /\b1 line item\b.+ success.+ 1 failed\b/
          end

          it_behaves_like "it imported no orders"
        end

        context "the second order detail fails" do
          let(:upload_file) { fixture_file("second_od_error.csv") }

          before(:each) { do_request }

          it_behaves_like "it imported no orders"
        end
      end

      context "save complete orders (default) mode" do
        let(:fail_on_error) { false }

        context "the first order detail fails" do
          let(:upload_file) { fixture_file("first_od_error.csv") }

          before(:each) { do_request }

          it_behaves_like "it imported no orders"
        end

        context "the second order detail fails" do
          let(:upload_file) { fixture_file("second_od_error.csv") }

          before(:each) { do_request }

          it_behaves_like "it imported no orders"
        end
      end
    end
  end
end
