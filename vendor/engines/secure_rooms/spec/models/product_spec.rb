# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  it "includes Secure Rooms in the type list" do
    expect(Product.types).to include(SecureRoom)
  end
end
