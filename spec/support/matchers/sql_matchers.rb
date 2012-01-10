if NUCore::Database.oracle?
  RSpec::Matchers.define :contain_beginning_of_day do |field, datetime|
    expected = "#{field.to_s} > TO_DATE('#{datetime.beginning_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')}','YYYY-MM-DD HH24:MI:SS')"
    match do |actual|
      actual.where_values.include? expected
    end
  end
  RSpec::Matchers.define :contain_end_of_day do |field, datetime|
    expected = "#{field.to_s} < TO_TIMESTAMP('#{datetime.end_of_day.utc.strftime('%Y-%m-%d %H:%M:%S:999999')}','YYYY-MM-DD HH24:MI:SS:FF6')"
    match do |actual|
      actual.where_values.include? expected
    end
  end
  RSpec::Matchers.define :contain_string_in_sql do |expected|
    expected = expected.gsub("\`", "\"").upcase  
    match do |actual|
      actual.to_sql.upcase.include? expected
    end
    failure_message_for_should do |actual|
      "expected that #{actual.to_sql.upcase} would include #{expected}"
    end

    failure_message_for_should_not do |actual|
      "expected that #{actual.to_sql.upcase} would not include #{expected}"
    end
  end
else
  RSpec::Matchers.define :contain_end_of_day do |field, datetime|
    expected = "#{field.to_s} < '#{datetime.end_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')}'"
    match do |actual|
      actual.where_values.include? expected
    end
  end
  RSpec::Matchers.define :contain_beginning_of_day do |field, datetime|
    expected = "#{field.to_s} > '#{datetime.beginning_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')}'"
    match do |actual|
      actual.where_values.include? expected
    end
  end
  RSpec::Matchers.define :contain_string_in_sql do |expected|
    match do |actual|
      actual.to_sql.include? expected
    end
  end
end
