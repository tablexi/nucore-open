# frozen_string_literal: true

module Projects

  module GlobalSearchControllerExtension

    extend ActiveSupport::Concern

    included do
      searcher_classes.unshift(Projects::GlobalSearch::ProjectSearcher)
    end

  end

end
