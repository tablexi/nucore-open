FactoryGirl.define do
  factory :stored_file do
    swf_uploaded_data { fixture_file_upload("#{Rails.root}/spec/files/flash_file.swf", "application/x-shockwave-flash") }
    name "#{Rails.root}/spec/files/flash_file.swf"
    file_type "info"
  end

  factory :csv_stored_file, class: StoredFile do
    file { StringIO.new("c,s,v") }
    file_type { "import_upload" }
    name { "clean_import.csv" }
    association :creator, factory: :user
  end

  trait :template do
    file { StringIO.new("c,s,v") }
    file_type { "template" }
    name { "template.csv" }
    association :creator, factory: :user
  end
end
