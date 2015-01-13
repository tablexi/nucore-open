require "spec_helper"

describe OrderRowImporter do
  subject { OrderRowImporter.new(row, order_import) }
  let(:order_import) { OrderImport.new }

  describe "#import" do
    context "when the fulfillment date is invalid" do
      it "does not import the row"
      it "flags the fulfillment date as invalid"
    end

    context "when the order date is invalid" do
      it "does not import the row"
      it "flags the order date as invalid"
    end

    context "when the user is invalid" do
      context "when looking up by username" do
        it "does not import the row"
        it "flags the username as invalid"
      end

      context "when looking up by email address" do
        it "does not import the row"
        it "flags the username as invalid"
      end
    end

    context "when the product name is invalid" do
      it "does not import the row"
      it "flags the product name as invalid"
    end

    context "when the product is a service" do
      context "and it requires a survey" do
        it "does not import the row"
        it "flags the service as requiring a survey"
      end

      context "and it requires a template" do
        it "does not import the row"
        it "flags the service as requiring a template"
      end
    end

    context "when the user has an account for the product's facility" do
      context "and the account is active" do
        context "and the account is invalid for the product" do
          it "does not import the row"
          it "flags the account as invalid"
        end

        context "and the account is valid for the product" do
          context "when the order was not purchased" do
            context "and the order is valid" do
              context "and is not purchaseable" do
                it "does not import the row"
                it "flags the order as not purchaseable"
              end
            end

            context "and the order is invalid" do
              it "does not import the row"
              it "flags the order as invalid"
            end
          end
        end
      end

      context "and the account is inactive" do
        it "does not import the row"
        it "flags that it cannot find an account"
      end
    end
  end

  context "order key construction" do
    let(:row) {{
      "Netid / Email" => "one",
      "Chart String" => "two",
      "Product Name" => "three",
      "Quantity" => "four",
      "Order Date" => "five",
      "Fulfillment Date" => "six",
      "Errors" => "seven",
      "Note" => "eight",
    }}

    describe ".order_key_for_row" do
      it "builds an array based on the expected fields" do
        expect(OrderRowImporter.order_key_for_row(row)).to eq %w(one two five)
      end
    end

    describe "#order_key" do
      it "builds an array based on the expected fields" do
        expect(subject.order_key).to eq %w(one two five)
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
