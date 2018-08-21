# frozen_string_literal: true

module SangerSequencing

  class WellPlateConfiguration

    def initialize(reserved_cells: [])
      @reserved_cells = reserved_cells
    end

    CONFIGS = ActiveSupport::HashWithIndifferentAccess.new(
      default: new(reserved_cells: %w(A01 A02)),
      fragment: new(reserved_cells: []),
    ).freeze

    def self.find(key)
      CONFIGS[key] || CONFIGS[:default]
    end

    def to_json
      {
        reserved_cells: Array(@reserved_cells),
      }.to_json
    end

  end

end
