require_relative 'ipp_reporter'

namespace :price_policies do
  namespace :instrument do

    task comparison: :environment do
      IppReporter.new.report_changes
    end

  end
end
