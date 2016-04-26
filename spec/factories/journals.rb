FactoryGirl.define do
  factory :journal do
    is_successful true
    created_by 1
    journal_date { Time.zone.now }

    trait :with_completed_order do
      facility

      transient do
        quantities [1]

        facility_account do
          facility
            .facility_accounts
            .create(FactoryGirl.attributes_for(:facility_account))
        end

        order { FactoryGirl.create(:purchased_order, product: product) }

        product do
          FactoryGirl.create(:setup_item, facility: facility, facility_account: facility_account)
        end

      end

      after(:build) do |_journal, evaluator|
        order_details = evaluator.order.order_details

        evaluator.quantities.each_with_index do |quantity, index|
          order_detail = order_details[index]
          if order_detail.present?
            order_detail.update_attribute(:quantity, quantity)
          else
            order_details.create(FactoryGirl.attributes_for(:order_detail, product: evaluator.product, quantity: quantity))
          end
        end

        order_details.update_all(account_id: evaluator.order.account_id)

        evaluator.order.reload.order_details.each(&:to_complete!)
      end

      after(:create) do |journal, evaluator|
        journal.create_journal_rows!(evaluator.order.order_details)
      end
    end
  end
end
