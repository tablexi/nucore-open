class JournalCutoffDate < ActiveRecord::Base

  include ActiveModel::ForbiddenAttributesProtection

  validates :cutoff_date, presence: true
  validate :unique_month_for_cutoff_date, if: :cutoff_date?

  scope :recent_and_upcoming, -> { where("cutoff_date > ?", 1.month.ago.beginning_of_month).order(:cutoff_date) }
  scope :past, -> { where("cutoff_date < ?", Time.current).order(:cutoff_date) }

  def self.first_valid_date
    past.last.try(:cutoff_date).try(:beginning_of_month)
  end

  def last_valid_date
    cutoff_date.prev_month.end_of_month
  end

  def past?
    cutoff_date < Time.current
  end

  # TODO: consider turning this into a reusable module
  def cutoff_date_time=(hash)
    formatted = "#{cutoff_date.to_date} #{hash[:hour]}:#{hash[:minute]}#{hash[:ampm]}"
    self.cutoff_date = Time.zone.parse(formatted)
  end

  def cutoff_date_time
    {
      hour: cutoff_date.strftime("%-l"),
      minute:  "%02d" % cutoff_date.min,
      ampm: cutoff_date.strftime("%p"),
    }
  end

  private

  def unique_month_for_cutoff_date
    query = self.class
                .month_equal(cutoff_date.month)
                .year_equal(cutoff_date.year)

    # Do not conflict with itself
    query = query.where("id != ?", id) if persisted?

    if query.exists?
      errors.add(:cutoff_date, :month_taken, month: I18n.l(cutoff_date, format: "%B"))
    end
  end

  def self.month_equal(month)
    time_section_equal("MONTH", month)
  end

  def self.year_equal(year)
    time_section_equal("YEAR", year)
  end

  def self.time_section_equal(section, time)
    if NUCore::Database.oracle?
      # EXTRACT(MONTH from cutoff_date)
      where("EXTRACT(#{section} FROM cutoff_date) = ?", time)
    else
      # MONTH(cutoff_date)
      where("#{section}(cutoff_date) = ?", time)
    end
  end

end
