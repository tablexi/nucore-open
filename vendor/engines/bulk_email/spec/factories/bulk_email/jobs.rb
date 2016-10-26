FactoryGirl.define do
  factory :bulk_email_job, class: BulkEmail::Job do
    subject "Bulk Email Subject Line"
    sender "sender@example.com"
    recipients '["r1@example.com","r2@example.net","r3@example.org"]'
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
