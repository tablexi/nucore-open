# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewHookHelper do
  let(:placement) { "placement1" }

  describe "passing the proper path" do
    before { assign(:virtual_path, path) }

    describe "a partial" do
      let(:path) { "facilities/shared/_testing" }

      it "replaces slashes and the underscore with dots" do
        expect(ViewHook).to receive(:render_view_hook)
          .with("facilities.shared.testing", "placement1", anything, {})
        helper.render_view_hook(placement)
      end
    end

    describe "a non-partial template" do
      let(:path) { "facilities/show" }

      it "replaces slashes and the underscore with dots" do
        expect(ViewHook).to receive(:render_view_hook)
          .with("facilities.show", "placement1", anything, {})
        helper.render_view_hook(placement)
      end
    end
  end
end
