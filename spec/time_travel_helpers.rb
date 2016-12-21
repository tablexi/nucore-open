module TimeTravelHelpers

  def travel_and_return(interval)
    current_time = Time.current
    travel(interval)
    yield
    travel_to(current_time)
  end

  def travel_to_and_return(time)
    current_time = Time.current
    travel_to(time)
    yield
    travel_to(current_time)
  end

end
