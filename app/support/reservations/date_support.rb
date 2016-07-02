# Support for reading/writing reservation and actual start and
# end times using values split across text inputs
module Reservations::DateSupport

  extend ActiveSupport::Concern

  included do
    attr_writer :duration_mins, :duration_value, :duration_unit,
                :reserve_start_date, :reserve_start_hour, :reserve_start_min, :reserve_start_meridian,
                :actual_start_date, :actual_start_hour, :actual_start_min, :actual_start_meridian,
                :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian,
                :actual_duration_mins

    # Use only in tests to make creation a little easier
    attr_accessor :split_times
    before_validation :set_all_split_times, if: :split_times
  end

  def assign_times_from_params(params)
    assign_reserve_from_params(params) if admin_editable?
    assign_actuals_from_params(params) if can_edit_actuals?

    set_all_split_times
  end

  #
  # Virtual attributes
  #
  def reserve_start_hour
    hour_field(:reserve_start)
  end

  def reserve_start_min
    min_field(:reserve_start)
  end

  def reserve_start_meridian
    meridian_field(:reserve_start)
  end

  def reserve_end_hour
    hour_field(:reserve_end)
  end

  def reserve_start_date
    date_field(:reserve_start)
  end

  def reserve_end_min
    min_field(:reserve_end)
  end

  def reserve_end_meridian
    meridian_field(:reserve_end)
  end

  def reserve_end_date
    date_field(:reserve_end)
  end

  def duration_value
    return nil unless reserve_end_at && reserve_start_at

    unless @duration_value
      # default to minutes
      @duration_value = (reserve_end_at - reserve_start_at) / 60
      @duration_unit  = "minutes"
    end
    @duration_value.to_i
  end

  def duration_unit
    # default to minutes
    @duration_unit ||= "minutes"
  end

  def duration_mins
    if @duration_mins
      @duration_mins.to_i
    elsif reserve_end_at && reserve_start_at
      duration_with_seconds_stripped(reserve_start_at, reserve_end_at)
    else
      0
    end
  end

  def actual_duration_mins(base_time = Time.zone.now)
    if @actual_duration_mins
      @actual_duration_mins.to_i
    elsif actual_start_at
      end_at = actual_end_at || base_time
      [duration_with_seconds_stripped(actual_start_at, end_at), 1].max
    else
      0
    end
  end

  def actual_start_date
    date_field(:actual_start)
  end

  def actual_start_hour
    hour_field(:actual_start)
  end

  def actual_start_min
    min_field(:actual_start)
  end

  def actual_start_meridian
    meridian_field(:actual_start)
  end

  def actual_end_date
    date_field(:actual_end)
  end

  def actual_end_hour
    hour_field(:actual_end)
  end

  def actual_end_min
    min_field(:actual_end)
  end

  def actual_end_meridian
    meridian_field(:actual_end)
  end

  private

  def instance_variable_fetch(field, options = {})
    options.reverse_merge!(to_i: false)
    result = instance_variable_get("@#{field}") || yield
    result = result.to_i if options[:to_i]
    result
  end

  def date_field(field)
    instance_variable_fetch("#{field}_date") do
      send("#{field}_at").try(:strftime, "%m/%d/%Y")
    end
  end

  def hour_field(field)
    instance_variable_fetch("#{field}_hour", to_i: true) do
      human_hour(send("#{field}_at"))
    end
  end

  def meridian_field(field)
    instance_variable_fetch("#{field}_meridian") do
      send("#{field}_at").try(:strftime, "%p")
    end
  end

  def min_field(field)
    instance_variable_fetch("#{field}_min", to_i: true) do
      send("#{field}_at").try(:min)
    end
  end

  def human_hour(time)
    return unless time
    hour = time.hour.to_i % 12
    hour == 0 ? 12 : hour
  end

  def set_all_split_times
    set_reserve_start_at
    set_reserve_end_at
    set_actual_start_at
    set_actual_end_at
  end

  def assign_reserve_from_params(params)
    # need to be reset to nil so the individual pieces will
    # take precedence
    self.reserve_start_at = nil
    self.reserve_end_at   = nil
    reserve_attrs = params.slice(:reserve_start_date, :reserve_start_hour, :reserve_start_min, :reserve_start_meridian,
                                 :duration_value, :duration_unit, :duration_mins,
                                 :reserve_start_at, :reserve_end_at)
    assign_attributes reserve_attrs
  end

  def assign_actuals_from_params(params)
    self.actual_start_at = nil
    self.actual_end_at   = nil
    reserve_attrs = params.slice(:actual_start_date, :actual_start_hour, :actual_start_min, :actual_start_meridian,
                                 :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian,
                                 :actual_start_at, :actual_end_at, :actual_duration_mins)

    reserve_attrs.reject! { |_key, value| value.blank? }

    assign_attributes reserve_attrs
  end

  # set set_reserve_start_at based on reserve_start_xxx virtual attributes
  def set_reserve_start_at
    return unless reserve_start_at.blank?
    if @reserve_start_date && @reserve_start_hour && @reserve_start_min && @reserve_start_meridian
      self.reserve_start_at = parse_usa_date(@reserve_start_date, "#{@reserve_start_hour}:#{@reserve_start_min.to_s.rjust(2, '0')} #{@reserve_start_meridian}")
    end
  end

  # set reserve_end_at based on duration_value, duration_unit virtual attribute
  def set_reserve_end_at
    return if reserve_end_at.present? || reserve_start_at.blank?
    unless @duration_mins
      case @duration_unit
      when "minutes", "minute"
        @duration_mins = @duration_value.to_i
      when "hours", "hour"
        @duration_mins = @duration_value.to_i * 60
      else
        @duration_mins = 0
      end
    end
    self.reserve_end_at = reserve_start_at + @duration_mins.to_i.minutes
  end

  def set_actual_start_at
    return if actual_start_at.present?
    if @actual_start_date && @actual_start_hour && @actual_start_min && @actual_start_meridian
      self.actual_start_at = parse_usa_date(@actual_start_date, "#{@actual_start_hour}:#{@actual_start_min.to_s.rjust(2, '0')} #{@actual_start_meridian}")
    end
  end

  def set_actual_end_at
    return if actual_end_at.present?
    if @actual_end_date && @actual_end_hour && @actual_end_min && @actual_end_meridian
      self.actual_end_at = parse_usa_date(@actual_end_date, "#{@actual_end_hour}:#{@actual_end_min.to_s.rjust(2, '0')} #{@actual_end_meridian}")
    elsif @actual_duration_mins && actual_start_at
      self.actual_end_at = actual_start_at + @actual_duration_mins.to_i.minutes
    end
  end

  def duration_with_seconds_stripped(start_time, end_time)
    ((end_time.change(sec: 0) - start_time.change(sec: 0)) / 60).to_i
  end

end
