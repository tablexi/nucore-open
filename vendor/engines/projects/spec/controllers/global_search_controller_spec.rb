require "rails_helper"

RSpec.describe GlobalSearchController do
  describe ".searcher_classes" do
    it "includes the project searcher" do
      expect(described_class.searcher_classes)
        .to include(Projects::GlobalSearch::ProjectSearcher)
    end
  end
end
