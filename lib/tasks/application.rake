namespace :credit_card do
  desc "Update credit cards so they have an associated facility"
  task :update_facility => :environment do
    credit_cards = CreditCardAccount.where(:facility_id => nil)
    credit_cards.each do |card|
      used_facilities = []
      card.orders.each do |order|
        used_facilities << order.facility.id
      end
      used_facilities.uniq!
      puts "credit card #{card.id} was used at facilities #{used_facilities}"
      if used_facilities.size == 1
        puts "  updating facility to #{used_facilities[0]}"
        card.facility_id = used_facilities[0]
        card.save!(:validate => false)
      elsif used_facilities.size == 0
        puts "WARNING: CreditCard ##{card.id} does not have any purchases, cannot assign a facility"
      else
        puts "WARNING: CreditCard ##{card.id} was used at multiple facilities. Please resolve manually."
      end
    end
  end
end