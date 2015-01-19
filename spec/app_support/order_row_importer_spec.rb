require "spec_helper"

describe OrderRowImporter do
  subject { OrderRowImporter.new(row, order_import) }
  let(:account) do
    create(:nufs_account,
      account_users_attributes: [ attributes_for(:account_user, user: user) ],
    )
  end
  let(:facility) { create(:facility) }
  let(:facility_account) do
    facility.facility_accounts.create(attributes_for(:facility_account))
  end
  let(:order_import) { build(:order_import, creator: user, facility: facility) }
  let(:service) do
    create(:setup_service,
      facility: facility,
      facility_account: facility_account,
    )
  end
  let(:user) { create(:user) }

  let(:row) {{
    "Netid / Email" => username,
    "Chart String" => chart_string,
    "Product Name" => product_name,
    "Quantity" => quantity,
    "Order Date" => order_date,
    "Fulfillment Date" => fulfillment_date,
    "Errors" => errors,
    "Note" => notes,
  }}

  let(:username) { "column1" }
  let(:chart_string) { "column2" }
  let(:product_name) { "column3" }
  let(:quantity) { "column4" }
  let(:order_date) { "column5" }
  let(:fulfillment_date) { "column6" }
  let(:errors) { "column7" }
  let(:notes) { "column8" }

  describe "#import" do
    shared_examples_for "an order was created" do
      it "creates an order" do
        expect { subject.import }.to change(Order, :count).by(1)
      end
    end

    shared_examples_for "an order was not created" do
      it "does not create an order" do
        expect { subject.import }.not_to change(Order, :count)
      end

      it "does not add an order_detail" do
        expect { subject.import }.not_to change(OrderDetail, :count)
      end
    end

    context "when the fulfillment date is invalid" do
      it_behaves_like "an order was not created"

      it "flags the fulfillment date as invalid" do
        subject.import
        expect(subject.errors)
          .to include_a_string_matching(/Invalid Fulfillment Date/)
      end
    end

    context "when the order date is invalid" do
      it_behaves_like "an order was not created"

      it "flags the order date as invalid" do
        subject.import
        expect(subject.errors)
          .to include_a_string_matching(/Invalid Order Date/)
      end
    end

    context "when the user is invalid" do
      context "when looking up by username" do
        it_behaves_like "an order was not created"

        it "flags the username as invalid" do
          subject.import
          expect(subject.errors)
            .to include_a_string_matching(/Invalid username/)
        end
      end

      context "when looking up by email address" do
        it_behaves_like "an order was not created"

        it "flags the username as invalid" do
          subject.import
          expect(subject.errors)
            .to include_a_string_matching(/Invalid username/)
        end
      end
    end

    context "when the product name is invalid" do
      it_behaves_like "an order was not created"

      it "flags the product name as invalid" do
        subject.import
        expect(subject.errors)
          .to include_a_string_matching(/Couldn't find product by name/)
      end
    end

    context "when the product is a service" do
      let(:chart_string) { account.account_number }
      let(:price_group) { create(:price_group, facility: facility) }
      let(:product) { service }
      let(:product_name) { product.name }
      let(:username) { user.username }

      before(:each) do
        create(:user_price_group_member, user: user, price_group: price_group)
        product.service_price_policies.create(
          attributes_for(:service_price_policy, price_group: price_group)
        )
      end

      context "and it requires a survey" do
        before { Service.any_instance.stub(:active_survey?).and_return(true) }

        it_behaves_like "an order was not created"

        it "flags the service as requiring a survey" do
          subject.import
          expect(subject.errors)
            .to include_a_string_matching(/Service requires survey/)
        end
      end

      context "and it requires a template" do
        before { Service.any_instance.stub(:active_template?).and_return(true) }

        it_behaves_like "an order was not created"

        it "flags the service as requiring a template" do
          subject.import
          expect(subject.errors)
            .to include_a_string_matching(/Service requires template/)
        end
      end
    end

    context "when the user has an account for the product's facility" do
      let(:chart_string) { account.account_number }
      let(:fulfillment_date) { "1/1/1999" }
      let(:order_date) { "1/1/1999" }
      let(:product) { service }
      let(:product_name) { product.name }
      let(:username) { user.username }

      before(:each) do
        User.any_instance.stub(:accounts)
          .and_return(Account.where(id: account.id))
      end

      context "and the account is active" do
        before { Account.any_instance.stub(:is_active?).and_return(true) }

        context "and the account is invalid for the product" do
          before(:each) do
            Facility.any_instance.stub(:can_pay_with_account?).and_return(false)
          end

          it_behaves_like "an order was not created"

          it "flags the account as invalid" do
            subject.import
            expect(subject.errors)
              .to include_a_string_matching(/does not accept.+payment/)
          end
        end

        context "and the account is valid for the product" do
          before { Product.any_instance.stub(:can_purchase?).and_return(true) }

          context "when the order was not purchased" do
            before(:each) do
              Order.any_instance.stub(:purchased?).and_return(false)
              Order.any_instance.stub(:purchase!).and_return(false)
            end

            context "and the order is valid" do
              before(:each) do
                Order.any_instance.stub(:validate_order!).and_return(true)
              end

              context "and is not purchaseable" do
                # Creating an Order in this case is existing behavior.
                # In practice we run the import in a transaction and roll back.
                it_behaves_like "an order was created"

                it "flags the order as not purchaseable" do
                  subject.import
                  expect(subject.errors)
                    .to include_a_string_matching(/Couldn't purchase order/)
                end
              end
            end

            context "and the order is invalid" do
              # Creating an Order in this case is existing behavior.
              # In practice we run the import in a transaction and roll back.
              it_behaves_like "an order was created"

              it "flags the order as invalid" do
                subject.import
                expect(subject.errors)
                  .to include_a_string_matching(/Couldn't validate order/)
              end
            end
          end
        end
      end

      context "and the account is inactive" do
        before { account.update_attribute(:suspended_at, 1.year.ago) }

        it_behaves_like "an order was not created"

        it "flags that it cannot find an account" do
          subject.import
          expect(subject.errors)
            .to include_a_string_matching(/Can't find account/)
        end
      end
    end
  end

  context "order key construction" do
    let(:expected_order_key) { %w(column1 column2 column5) }

    describe ".order_key_for_row" do
      it "builds an array based on the expected fields" do
        expect(OrderRowImporter.order_key_for_row(row)).to eq expected_order_key
      end
    end

    describe "#order_key" do
      it "builds an array based on the expected fields" do
        expect(subject.order_key).to eq expected_order_key
      end
    end
  end

  describe "#row_with_errors" do
    let(:errors) { %w(one two three) }
    let(:row) {{ "Errors" => "" }}

    context "when the import has no errors" do
      it "does not add errors to the error column" do
        expect(subject.row_with_errors["Errors"]).to be_blank
      end
    end

    context "when the import has errors" do
      before { errors.each { |error| subject.send(:add_error, error) } }

      it "adds errors to the error column" do
        expect(subject.row_with_errors["Errors"]).to eq(errors.join(", "))
      end
    end
  end
end
