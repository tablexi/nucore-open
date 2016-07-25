module SangerSequencing

  class WellPlateConfiguration

    def initialize(reserved_cells: [])
      @reserved_cells = reserved_cells
    end

    CONFIGS = ActiveSupport::HashWithIndifferentAccess.new(
      default: new(reserved_cells: ["A01", "A02"]),
      fragment: new(reserved_cells: [])
    ).freeze

    def self.find(key)
      CONFIGS[key]
    end

    def to_json
      {
        reserved_cells: Array(@reserved_cells)
      }.to_json
    end

  end

end
