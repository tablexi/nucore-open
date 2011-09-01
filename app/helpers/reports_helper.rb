module ReportsHelper

  def to_hours(minutes)
    (minutes / 60).round(2)
  end


  def to_percent(decimal)
    (decimal * 100).round
  end

end