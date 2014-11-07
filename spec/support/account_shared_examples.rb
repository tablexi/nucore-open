shared_examples_for "an Account" do
  context "#to_s" do
    context "when not suspended" do
      it "does not append '(suspended)'" do
        expect(account.to_s).not_to match /\s+\(suspended\)\Z/
      end
    end

    context "when suspended" do
      before { account.update_attribute(:suspended_at, Time.zone.now) }

      it "appends '(suspended)'" do
        expect(account.to_s).to match /\s+\(suspended\)\Z/
      end
    end
  end
end
