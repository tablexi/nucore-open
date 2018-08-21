# frozen_string_literal: true

RSpec.shared_examples_for "the user must log in" do
  it "redirects to the login screen" do
    expect(response).to be_redirect
    expect(response.location).to eq(new_user_session_url)
  end
end

RSpec.shared_examples_for "the user is not allowed" do
  it { expect(response).to be_forbidden }
end
