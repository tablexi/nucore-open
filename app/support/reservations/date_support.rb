# Support for reading/writing reservation and actual start and
# end times using values split across text inputs
module Reservations::DateSupport
  extend ActiveSupport::Concern

  included do
    attr_writer :duration_mins, :duration_value, :duration_unit,
                :reserve_start_date, :reserve_start_hour, :reserve_start_min, :reserve_start_meridian,
                :actual_start_date, :actual_start_hour, :actual_start_min, :actual_start_meridian,
                :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian
    
    before_validation :set_all_split_times
  end

  def set_all_split_times
    set_reserve_start_at
    set_reserve_end_at
    set_actual_start_at
    set_actual_end_at
  end

  # set set_reserve_start_at based on reserve_start_xxx virtual attributes
  def set_reserve_start_at
    return unless self.reserve_start_at.blank?
    if @reserve_start_date and @reserve_start_hour and @reserve_start_min and @reserve_start_meridian
      self.reserve_start_at = parse_usa_date(@reserve_start_date, "#{@reserve_start_hour.to_s}:#{@reserve_start_min.to_s.rjust(2, '0')} #{@reserve_start_meridian}")
    end
  end

  # set reserve_end_at based on duration_value, duration_unit virtual attribute
  def set_reserve_end_at
    return unless self.reserve_end_at.blank?
    case @duration_unit
    when 'minutes', 'minute'
      @duration_mins = @duration_value.to_i
    when 'hours', 'hour'
      @duration_mins = @duration_value.to_i * 60
    else
      @duration_mins = 0
    end
    self.reserve_end_at = self.reserve_start_at + @duration_mins.minutes
  end

  def set_actual_start_at
    return unless self.actual_start_at.blank?
    if @actual_start_date and @actual_start_hour and @actual_start_min and @actual_start_meridian
      self.actual_start_at = parse_usa_date(@actual_start_date, "#{@actual_start_hour.to_s}:#{@actual_start_min.to_s.rjust(2, '0')} #{@actual_start_meridian}")
    end
  end

  def set_actual_end_at
    return unless self.actual_end_at.blank?
    if @actual_end_date and @actual_end_hour and @actual_end_min and @actual_end_meridian
      self.actual_end_at = parse_usa_date(@actual_end_date, "#{@actual_end_hour.to_s}:#{@actual_end_min.to_s.rjust(2, '0')} #{@actual_end_meridian}")
    end
  end

  #
  # Virtual attributes
  #
  def reserve_start_hour
    case
    when @reserve_start_hour
      @reserve_start_hour.to_i
    when !reserve_start_at.blank?
      hour = reserve_start_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def reserve_start_min
    case
    when @reserve_start_min
      @reserve_start_min.to_i
    when !reserve_start_at.blank?
      reserve_start_at.min
    else
      nil
    end
  end

  def reserve_start_meridian
    case
    when @reserve_start_meridian
      @reserve_start_meridian
    when !reserve_start_at.blank?
      reserve_start_at.strftime("%p")
    else
      nil
    end
  end

  def reserve_end_hour
    case
    when @reserve_end_hour
      @reserve_end_hour
    when !reserve_end_at.blank?
      hour = reserve_end_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def reserve_start_date
    case
    when @reserve_start_date
      @reserve_start_date
    when !reserve_start_at.blank?
      reserve_start_at.strftime("%m/%d/%Y")
    else
      nil
    end
  end

  def reserve_end_min
    case
    when @reserve_end_min
      @reserve_end_min
    when !reserve_end_at.blank?
      reserve_end_at.min
    else
      nil
    end
  end

  def reserve_end_meridian
    reserve_end_at.nil? ? nil : reserve_end_at.strftime("%p")
  end

  def reserve_end_date
    reserve_end_at.nil? ? nil : reserve_end_at.strftime("%m/%d/%Y")
  end

  def duration_value
    return nil unless reserve_end_at && reserve_start_at

    if !@duration_value
      # default to minutes
      @duration_value = (reserve_end_at - reserve_start_at) / 60
      @duration_unit  = 'minutes'
    end
    @duration_value.to_i
  end

  def duration_unit
    # default to minutes
    @duration_unit ||= 'minutes'
  end

  def duration_mins
    if @duration_mins
      @duration_mins.to_i
    elsif reserve_end_at and reserve_start_at
      @duration_mins = (reserve_end_at - reserve_start_at) / 60
    else
      @duration_mins = 0
    end
  end

  def actual_duration_mins
    if @actual_duration_mins
      @actual_duration_mins.to_i
    elsif actual_end_at && actual_start_at
      @actual_duration_mins = (actual_end_at - actual_start_at) / 60
    else
      @duration_mins = 0
    end
  end

  def actual_start_date
    case
    when @actual_start_date
      @actual_start_date
    when !actual_start_at.blank?
      actual_start_at.strftime("%m/%d/%Y")
    else
      nil
    end
  end

  def actual_start_hour
    case
    when @actual_start_hour
      @actual_start_hour.to_i
    when !actual_start_at.blank?
      hour = actual_start_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def actual_start_min
    case
    when @actual_start_min
      @actual_start_min.to_i
    when !actual_start_at.blank?
      actual_start_at.min
    else
      nil
    end
  end

  def actual_start_meridian
    case
    when @actual_start_meridian
      @actual_start_meridian
    when !actual_start_at.blank?
      actual_start_at.strftime("%p")
    else
      nil
    end
  end

  def actual_end_date
    case
    when @actual_end_date
      @actual_end_date
    when !actual_end_at.blank?
      actual_end_at.strftime("%m/%d/%Y")
    else
      nil
    end
  end

  def actual_end_hour
    case
    when @actual_end_hour
      @actual_end_hour.to_i
    when !actual_end_at.blank?
      hour = actual_end_at.hour.to_i % 12
      hour == 0 ? 12 : hour
    else
      nil
    end
  end

  def actual_end_min
    case
    when @actual_end_min
      @actual_end_min.to_i
    when !actual_end_at.blank?
      actual_end_at.min
    else
      nil
    end
  end

  def actual_end_meridian
    case
    when @actual_end_meridian
      @actual_end_meridian
    when !actual_end_at.blank?
      actual_end_at.strftime("%p")
    else
      nil
    end
  end
end