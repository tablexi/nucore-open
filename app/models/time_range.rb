class TimeRange
  attr_reader :start_at, :end_at

  def initialize(start_at, end_at)
    @start_at = start_at
    @end_at = end_at
  end

  def to_s
    "#{start_string} - #{end_string}"
  end

  def duration_mins
    ((end_at.change(sec: 0) - start_at.change(sec: 0)) / 60).to_i
  end

  private

  def start_string
    l(start_at)
  end

  def end_string
    if start_at && end_at && start_at.day == end_at.day
      l(end_at, format: :timeonly)
    else
      l(end_at)
    end
  end

  def l(time, *options)
    time ? I18n.l(time, *options) : "???"
  end
end
