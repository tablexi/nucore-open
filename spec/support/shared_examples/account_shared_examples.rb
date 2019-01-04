# frozen_string_literal: true

RSpec.shared_examples_for "an Account" do
  context "#to_s" do
    context "when not suspended" do
      it "does not append '(SUSPENDED)'" do
        expect(account.to_s).not_to match(/\s+\(SUSPENDED\)\Z/)
      end
    end

    context "when suspended" do
      before { account.suspended_at = Time.current }

      it "appends '(SUSPENDED)'" do
        expect(account.to_s).to match(/\s+\(SUSPENDED\)\Z/)
      end
    end
  end
end
