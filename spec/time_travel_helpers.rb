module TimeTravelHelpers

  def travel(interval, safe: false)
    # See rails_helper
    warn "Use of Rails's #travel is unsafe in NUcore due to the global time-lock. Use `travel_and_return` instead #{caller(1..1)}" unless safe
    super(time)
  end

  def travel_to(time, safe: false)
    # See rails_helper
    warn "Use of Rails's #travel_to is unsafe in NUcore due to the global time-lock. Use `travel_to_and_return` instead #{caller(1..1)}" unless safe
    super(time)
  end

  def travel_and_return(interval)
    current_time = Time.current
    travel(interval, safe: true)
    yield
    travel_to(current_time, safe: true)
  end

  def travel_to_and_return(time)
    current_time = Time.current
    travel_to(time, safe: true)
    yield
    travel_to(current_time, safe: true)
  end

end
