# frozen_string_literal: true

require "spec_helper"
require "saml_authentication/saml_attributes"
require "devise_saml_authenticatable/saml_response"

RSpec.describe SamlAuthentication::SamlAttributes do
  let(:response_string) { Base64.encode64(File.read(File.expand_path("../../fixtures/login_response.xml", __dir__))) }
  let(:base_response) { OneLogin::RubySaml::Response.new(response_string) }
  let(:response) { ::SamlAuthenticatable::SamlResponse.new(base_response, attribute_map) }
  let(:attribute_map) do
    {
      "PersonImmutableID" => "username",
      "User.email" => "email",
      "User.FirstName" => "first_name",
      "User.LastName" => "last_name",
    }
  end

  subject(:attributes) { described_class.new(response) }

  it "makes the hash" do
    expect(attributes.to_h).to eq(
      "username" => "sst123",
      "email" => "sst123@example.com",
      "first_name" => "Sam",
      "last_name" => "Student",
    )
  end

  it "can access the values like a hash" do
    expect(attributes[:username]).to eq("sst123")
    expect(attributes[:email]).to eq("sst123@example.com")
  end

  it "can get every attribute" do
    expect(attributes.to_raw_h).to eq(
      "PersonImmutableID" => ["sst123"],
      "User.email" => ["sst123@example.com"],
      "User.FirstName" => ["Sam"],
      "User.LastName" => ["Student"],
      "memberOf" => [""]
    )
  end

end
