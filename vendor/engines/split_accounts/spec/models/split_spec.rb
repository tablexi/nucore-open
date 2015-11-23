require "rails_helper"

RSpec.describe Split, type: :model do

  # TODO: remove this if/when we do factory linting
  it "has a valid factory" do
    expect(build(:split)).to be_valid
  end

  describe "validations" do
    context "when self referential" do
      let(:split) do
        build(:split).tap do |split|
          split.subaccount = split.parent_split_account
        end
      end

      it "is invalid" do
        expect(split).to_not be_valid
      end
    end
  end

end
