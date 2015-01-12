require "spec_helper"
require "controller_spec_helper"

require "stringio"
require "csv_helper"

CSV_HEADERS = [
  "Netid / Email",
  "Chart String",
  "Product Name",
  "Quantity",
  "Order Date",
  "Fulfillment Date",
  "Note",
]

def nucore_format_date(date)
  date.strftime("%m/%d/%Y")
end

describe OrderImport do
  subject(:order_import) do
    OrderImport.create!(
      created_by: director.id,
      upload_file: stored_file,
      facility: facility,
    )
  end

  let(:account_users_attributes) do
    account_users_attributes_hash(user: guest) +
    account_users_attributes_hash(
      user: guest2,
      created_by: guest,
      user_role: AccountUser::ACCOUNT_PURCHASER,
    )
  end
  let(:csv_row) { CSVHelper::CSV::Row.new(CSV_HEADERS, row_data) }
  let(:default_order_date) { 4.days.ago.to_date }
  let(:default_fulfilled_date) { 3.days.ago.to_date }
  let(:director) { @director }
  let(:error_file_row_count) do
    Paperclip
      .io_adapters
      .for(order_import.error_file.file)
      .read
      .split("\n")
      .count
  end
  let(:facility) { create(:facility) }
  let(:facility_account) do
    facility.facility_accounts.create!(attributes_for(:facility_account))
  end
  let(:fiscal_year_beginning) { SettingsHelper::fiscal_year_beginning }
  let(:guest) { @guest }
  let(:guest2) { create(:user, username: "guest2") }
  let(:import_errors) { order_import.errors_for(csv_row) }
  let(:import_file_row_count) { import_file.read.split("\n").count }
  let(:item) do
    facility.items.create!(attributes_for(:item,
      facility_account_id: facility_account.id,
      name: "Example Item",
    ))
  end
  let(:service) do
    facility.services.create!(attributes_for(:service,
      facility_account_id: facility_account.id,
      name: "Example Service",
    ))
  end
  let(:stored_file) do
    StoredFile.create!(
      file: StringIO.new("c,s,v"),
      file_type: "import_upload",
      name: "clean_import.csv",
      created_by: director.id,
    )
  end

  let(:row_data) {[ username, account_number, product_name, quantity, order_date, fulfillment_date, note ]}
  let(:username) { guest.username }
  let(:account_number) { "111-2222222-33333333-01" }
  let(:product_name) { "Example Item" }
  let(:quantity) { 1 }
  let(:order_date) { nucore_format_date(default_order_date) }
  let(:fulfillment_date) { nucore_format_date(default_fulfilled_date) }
  let(:note) { "Test note" }

  before(:all) { create_users }

  before :each do
    Timecop.freeze(fiscal_year_beginning + 5.days)

    grant_role(director, facility)

    price_group = facility.price_groups.create!(attributes_for(:price_group))
    create(:user_price_group_member, user: guest, price_group: price_group)
    item.item_price_policies.create!(attributes_for(:item_price_policy,
      price_group_id: price_group.id,
      start_date: fiscal_year_beginning,
    ))
    service.service_price_policies.create!(attributes_for(:service_price_policy,
      price_group_id: price_group.id,
      start_date: fiscal_year_beginning,
    ))

    create(:user_price_group_member, user: guest2, price_group: price_group)

    create(:nufs_account,
      description: "dummy account",
      account_number: '111-2222222-33333333-01',
      account_users_attributes: account_users_attributes,
    )
  end

  after { Timecop.return }

  shared_examples_for "it does not send notifications" do
    it "does not send notifications" do
      expect(Notifier).to receive(:order_receipt).never
      order_import.process!
    end
  end

  context "validations" do
    it { should belong_to :creator }
    it { should belong_to :upload_file }
    it { should belong_to :error_file }
    it { should validate_presence_of :upload_file }
    it { should validate_presence_of :created_by }
  end

  describe "errors_for(csv_row) (low-level) behavior" do
    context "with a valid row" do
      it "has no errors" do
        expect(import_errors).to be_empty
      end
    end

    context "with a nonexistent user" do
      let(:username) { "invalid_username" }

      it "generates a username error" do
        expect(import_errors.first).to match /user/
      end
    end

    context "with a nonexistent account" do
      let(:account_number) { "invalid_account" }

      it "generates an account error" do
        expect(import_errors.first).to match /find account/
      end
    end

    context "with a nonexistent product" do
      let(:product_name) { "invalid_product" }

      it "generates a product error" do
        expect(import_errors.first).to match /find product/
      end
    end

    context "with a deactivated (archived) product" do
      let(:product_name) { item.name }

      before { item.update_attributes(is_archived: true) }

      it "generates a product error" do
        expect(import_errors.first).to match /find product/
      end
    end

    context "with a hidden product" do
      let(:product_name) { item.name }

      before { item.update_attributes(is_hidden: true) }

      it "does not error" do
        expect(import_errors).to be_empty
      end
    end

    context "when the product is a service" do
      let(:product_name) { "Example Service" }

      context "with an active survey" do
        before :each do
          allow_any_instance_of(Service)
            .to receive(:active_survey?)
            .and_return(true)
        end

        it "generates a required survey error" do
          expect(import_errors.first).to match /requires survey/
        end
      end

      context "with an active template" do
        before :each do
          allow_any_instance_of(Service)
            .to receive(:active_template?)
            .and_return(true)
        end

        it "generates a required template error" do
          expect(import_errors.first).to match /requires template/
        end
      end
    end

    context "when the fulfillment_date" do
      context "is impossible" do
        let(:fulfillment_date) { "02/31/2012" }

        it "generates a fulfillment date error" do
          expect(import_errors.first).to match /Fulfillment Date/
        end
      end

      context "is incorrectly formatted" do
        let(:fulfillment_date) { "4-Apr-13" }

        it "generates a fulfillment date error" do
          expect(import_errors.first).to match /Fulfillment Date/
        end
      end
    end

    context "when the order_date" do
      context "is impossible" do
        let(:order_date) { "02/31/2012" }

        it "generates an order date error" do
          expect(import_errors.first).to match /Order Date/
        end
      end

      context "is incorrectly formatted" do
        let(:order_date) { "4-Apr-13" }

        it "generates an order date error" do
          expect(import_errors.first).to match /Order Date/
        end
      end
    end

    context "when specifying the user's email instead of username" do
      let(:username) { guest.email }

      it "does not error" do
        expect(import_errors).to be_empty
      end
    end

    describe "when creating an order" do
      let(:created_order) { Order.last }

      before { expect(import_errors).to be_empty }

      it "sets the ordered_at date appropriately" do
        expect(created_order.ordered_at.to_date).to eq(default_order_date)
      end

      it "sets the created_by_user to the creator of the import" do
        expect(created_order.created_by_user).to eq(director)
      end

      it "sets user to the user from the imported line" do
        expect(created_order.user).to eq(guest)
      end

      it { expect(created_order).to be_purchased }

      context "created order_details" do
        let(:note) { "This is a note" }

        it "exists as part of the newly created order" do
          expect(created_order).to have_details
        end

        it "has the expected product" do
          expect(created_order.order_details.first.product).to eq(item)
        end

        it "has a status of complete" do
          created_order.order_details.each do |order_detail|
            expect(order_detail).to be_complete
          end
        end

        it "has price policies" do
          created_order.order_details.each do |order_detail|
            expect(order_detail.price_policy).to be_present
          end
        end

        it "has no problem orders" do
          created_order.order_details.each do |order_detail|
            expect(order_detail).not_to be_problem_order
          end
        end

        it "has the expected fulfilled_at date for each order_detail" do
          created_order.order_details.each do |order_detail|
            expect(order_detail.fulfilled_at.to_date)
              .to eq(default_fulfilled_date)
          end
        end

        it "has the expected note for each order_detail" do
          created_order.order_details.each do |order_detail|
            expect(order_detail.note).to eq("This is a note")
          end
        end
      end
    end

    describe "with multiple rows" do
      let(:csv_rows) { rows.map { |row| CSVHelper::CSV::Row.new(CSV_HEADERS, row) } }
      let!(:initial_order_count) { Order.count }
      let(:reloaded_order_detail) { OrderDetail.find(OrderDetail.first.id).reload }

      before :each do
        csv_rows.each { |row| expect(order_import.errors_for(row)).to be_empty }
      end

      describe "with the same order_key" do
        let(:rows) do
          [
            [username, account_number, product_name, 2, order_date, nucore_format_date(2.days.ago), note],
            [username, account_number, product_name, 3, order_date, nucore_format_date(3.days.ago), note],
          ]
        end

        it "merges orders" do
          expect(Order.count - initial_order_count).to eq(1)
        end

        it "has no problem orders" do
          Order.last.order_details.each do |order_detail|
            expect(order_detail).not_to be_problem_order
          end
        end

        it "does not change previously attached details" do
          expect(reloaded_order_detail).to eq(OrderDetail.first)
        end
      end

      describe "with different order_keys" do
        let(:rows) do
          [
            [guest.username, account_number, product_name, 2, order_date, nucore_format_date(2.days.ago), note],
            [guest2.username, account_number, product_name, 3, order_date, nucore_format_date(3.days.ago), note],
          ]
        end

        it "does not merge orders" do
          expect(Order.count - initial_order_count).to be > 1
        end

        it "has no problem orders" do
          Order.last.order_details.each do |order_detail|
            expect(order_detail).not_to be_problem_order
          end
        end

        it "does not change previously attached details" do
          expect(reloaded_order_detail).to eq(OrderDetail.first)
        end
      end
    end
  end

def generate_import_file(*args)
  args = [{}] if args.length == 0 # default to at least one valid row

  whole_csv = CSVHelper::CSV.generate headers: true do |csv|
    csv << CSV_HEADERS
    args.each do |opts|
      row = CSVHelper::CSV::Row.new(CSV_HEADERS, [
        opts[:username]           || 'guest',
        opts[:account_number]     || "111-2222222-33333333-01",
        opts[:product_name]       || "Example Item",
        opts[:quantity]           || 1,
        opts[:order_date]         || nucore_format_date(default_order_date),
        opts[:fullfillment_date]  || nucore_format_date(default_fulfilled_date),
        opts[:note]               || "Test Note"
      ])
      csv << row
    end
  end

  return StringIO.new whole_csv
end

  describe "high-level calls" do
    context "when in save-clean-orders mode" do
      let(:import_file) do
        generate_import_file(
          # First order:
          { order_date: nucore_format_date(default_order_date) },
          { order_date: nucore_format_date(default_order_date) },
          # Second order (a different order_date):
          {
            order_date: nucore_format_date(default_order_date + 1.day),
            product_name: "Invalid Item"
          }
        )
      end

      before :each do
        order_import.fail_on_error = false
        order_import.send_receipts = true
        order_import.upload_file.file = import_file
        order_import.upload_file.save!
        order_import.save!
      end

      it "sends notifications" do
        expect(Notifier)
          .to receive(:order_receipt)
          .once
          .and_return(double(deliver: nil))

        order_import.process!
      end
    end

    context "when in save-nothing-on-error mode" do
      before :each do
        order_import.fail_on_error = true
        order_import.send_receipts = send_receipts
        order_import.upload_file.file = import_file
        order_import.upload_file.save!
        order_import.save!
      end

      context "with notifications enabled" do
        let(:send_receipts) { true }

        context "with errors" do
          let(:import_file) do
            generate_import_file({}, { product_name: "Invalid Item" })
          end

          it_behaves_like "it does not send notifications"
        end

        context "with no errors" do
          let(:import_file) { generate_import_file }

          it "sends notifications" do
            expect(Notifier)
              .to receive(:order_receipt)
              .once
              .and_return(double(deliver: nil))

            order_import.process!
          end
        end
      end

      context "with notifications disabled" do
        let(:import_file) { generate_import_file }
        let(:send_receipts) { false }

        it_behaves_like "it does not send notifications"
      end
    end
  end

  context "importing two orders" do
    context "when one order_detail has an error" do
      let(:import_file) do
        generate_import_file(
          # First order:
          { product_name: "Invalid Item" },
          {},
          # Second order (a different user):
          { username: guest2.username },
        )
      end

      before :each do
        Order.destroy_all
        order_import.upload_file.file = import_file
        order_import.upload_file.save!

        order_import.send_receipts = true
        order_import.save!

        import_file.rewind # because #save! reads the file
      end

      context "when in save-nothing-on-error mode" do
        before :each do
          order_import.fail_on_error = true
          order_import.save!
        end

        it "creates no orders" do
          expect { order_import.process! }.not_to change(Order, :count)
        end

        it_behaves_like "it does not send notifications"

        it "includes all rows in its error report" do
          order_import.process!
          expect(error_file_row_count).to eq(import_file_row_count)
        end
      end

      context "when in save-clean-orders mode" do
        before :each do
          order_import.fail_on_error = false
          order_import.save!
        end

        it "creates an order" do
          expect { order_import.process! }.to change(Order, :count).by(1)
        end

        it "sends a notification for second order" do
          expect(Notifier)
            .to receive(:order_receipt)
            .once
            .and_return(double(deliver: nil))

          order_import.process!
        end

        it "has the first two rows in its error report" do
          order_import.process!

          # minus one because one order (and order_detail) will succeed
          expect(error_file_row_count).to eq(import_file_row_count - 1)
        end
      end
    end
  end

  context "when importing multiple orders" do
    context "and the second order's order_detail has an error" do
      let(:import_file) do
        generate_import_file({}, { product_name: "Invalid Item" })
      end

      before :each do
        Order.destroy_all
        order_import.upload_file.file = import_file
        order_import.upload_file.save!
        import_file.rewind

        order_import.fail_on_error = fail_on_error
        order_import.send_receipts = true
        order_import.save!
      end

      shared_examples_for "an import failure" do
        it "creates no orders" do
          expect { order_import.process! }.not_to change(Order, :count)
        end

        it_behaves_like "it does not send notifications"

        it "includes all rows in its error report (as there's only one order)" do
          order_import.process!
          expect(error_file_row_count).to eq(import_file_row_count)
        end
      end

      context "when in save-clean-orders mode" do
        let(:fail_on_error) { false }

        it_behaves_like "an import failure"
      end

      context "when in save-nothing-on-error mode" do
        let(:fail_on_error) { true }

        it_behaves_like "an import failure"
      end
    end
  end
end
