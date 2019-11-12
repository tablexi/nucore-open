require "rails_helper"

RSpec.describe Users::ConvertInternalToExternalUser do
  let(:user) { create(:user, username: "int123", email: "int@example.org") }
  let!(:converter) { described_class.new(user.username) }

  it "converts the username" do
    expect { converter.convert! }.to change { user.reload.username }.to("int@example.org")
  end

  it "sets a random password" do
    expect { converter.convert! }.to change { user.reload.encrypted_password }.to be_present
  end
end
