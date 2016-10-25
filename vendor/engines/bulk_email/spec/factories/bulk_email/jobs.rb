FactoryGirl.define do
  factory :bulk_email_job, class: BulkEmail::Job do
    subject "Bulk Email Subject Line"
    recipients "[1,2,3,4,5]"
    search_criteria do
      {
        bulk_email: {
          user_types: [:customers],
          products: [1],
        },
        bulk_email_start_date: "1/1/2016",
        bulk_email_end_date: "12/31/2016",
      }
    end.to_json
  end
end
