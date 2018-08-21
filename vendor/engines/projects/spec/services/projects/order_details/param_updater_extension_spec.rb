# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::OrderDetails::ParamUpdaterExtension do
  describe ".permitted_attributes" do
    it "injects the :project_id attribute when the engine is active" do
      expect(::OrderDetails::ParamUpdater.permitted_attributes)
        .to include(:project_id)
    end
  end
end
