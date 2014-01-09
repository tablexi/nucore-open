require_relative 'ipp_reporter'

namespace :price_policies do
  namespace :instrument do

    desc <<-DOC
      Generates HTML and CSV reports detailing subsidy and cost differences
      between old and new instrument price policies on new, in process, and
      completed order details
    DOC
    task report: :environment do
      IppReporter.new.report_changes
    end


    desc <<-DOC
      Converts old instrument price policies to new and updates pricing on
      new, in process, and completed order details
    DOC
    task update: :environment do
      IppUpdater.new.update
    end

  end
end
