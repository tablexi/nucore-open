module SangerSequencing

  class WellPlatePresenter

    attr_reader :well_plate
    delegate :samples, to: :well_plate

    def initialize(well_plate)
      @well_plate = well_plate
    end

    def to_csv
      CSV.generate do |csv|
        csv << ["Container Name", "Plate ID", "Description", "ContainerType", "AppType", "Owner", "Operator", "PlateSealing", "SchedulingPref"]
        csv << ["",               "",         "",            "96-Well",       "Regular", "mb core", "mbcore", "Septa", "1234"]
        csv << %w(AppServer AppInstance)
        csv << ["SequencingAnalysis"]
        csv << ["Well", "Sample Name", "Comment", "Results Group 1", "Instrument Protocol 1", "Analysis Protocol 1"]

        sample_rows.each do |row|
          csv << row
        end
      end
    end

    def sample_rows
      cleaned_cells.map do |position, sample|
        [position] + sample_row(sample)
      end
    end

    private

    def cleaned_cells
      # Remove blank cells
      sorted_cells.reject { |_position, sample| sample.blank? }
    end

    def sorted_cells
      well_plate.cells.sort_by do |position, _sample|
        # Order by A01, B01, C01, etc.
        position =~ /\A([A-H])(\d{2})\z/
        [Regexp.last_match(2), Regexp.last_match(1)]
      end
    end

    def sample_row(sample)
      [sample.id.to_s, sample.customer_sample_id.to_s, "50cm_POP7_BDv3", "XLR_50POP7", "XLR__50POP7_KBSeqAna"]
    end

  end

end
