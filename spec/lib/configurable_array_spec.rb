require "spec_helper"
require "configurable_array"

RSpec.describe ConfigurableArray do
  let(:base) { described_class.new([:a, :b, :c]) }

  describe "insert_before" do
    it "can insert before the first element" do
      base.insert_before(:new, :a)
      expect(base).to eq([:new, :a, :b, :c])
    end

    it "can insert in the middle" do
      base.insert_before(:new, :b)
      expect(base).to eq([:a, :new, :b, :c])
    end

    it "inserts at the end if not found" do
      base.insert_before(:new, :not_found)
      expect(base).to eq([:a, :b, :c, :new])
    end
  end

  describe "insert_after" do
    it "can insert after the first element" do
      base.insert_after(:new, :a)
      expect(base).to eq([:a, :new, :b, :c])
    end

    it "can insert in the middle" do
      base.insert_after(:new, :b)
      expect(base).to eq([:a, :b, :new, :c])
    end

    it "can insert after the last element" do
      base.insert_after(:new, :c)
      expect(base).to eq([:a, :b, :c, :new])
    end

    it "inserts at the end if not found" do
      base.insert_after(:new, :not_found)
      expect(base).to eq([:a, :b, :c, :new])
    end
  end

end
