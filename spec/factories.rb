require File.expand_path("factories_env", File.dirname(__FILE__))

FactoryBot.define do
  factory :log_event do
    loggable { "" }
    event_type { "MyString" }
    user { nil }
  end
  trait :without_validation do
    to_create { |instance| instance.save(validate: false) }
  end
end
