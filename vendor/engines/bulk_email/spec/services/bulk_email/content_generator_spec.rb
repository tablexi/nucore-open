require "rails_helper"

RSpec.describe BulkEmail::ContentGenerator do
  let(:facility) { instrument.facility }
  let(:instrument) { FactoryGirl.build(:setup_instrument) }
  let(:recipient) { FactoryGirl.build(:user) }

  describe "#greeting" do
    context "without a recipient" do
      subject { described_class.new(facility, instrument) }

      it "generates a greeting with a placeholder name" do
        expect(subject.greeting).to include("Firstname Lastname")
      end
    end

    context "with a recipient" do
      subject { described_class.new(facility, instrument, recipient) }

      it "generates a greeting with a placeholder name" do
        expect(subject.greeting).to include(recipient.full_name)
      end
    end
  end

  describe "#signoff" do
    subject { described_class.new(facility) }

    it { expect(subject.signoff).to be_present }
  end

  describe "#subject_prefix" do
    subject { described_class.new(facility) }

    it "includes the app and facility names" do
      expect(subject.subject_prefix)
        .to eq("[#{I18n.t('app_name')} #{facility.name}]")
    end
  end

  describe "#wrap_text" do
    subject { described_class.new(facility, instrument, recipient) }

    it "wrapps content with the greeting and signoff" do
      expect(subject.wrap_text("This is some text"))
        .to eq("#{subject.greeting}\nThis is some text\n#{subject.signoff}")
    end
  end
end
