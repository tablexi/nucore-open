namespace :price_policies do
  namespace :instrument do

    task comparison: :environment do
      InstrumentPricePolicyComparator.new.report_changes
    end

  end
end
