require_relative 'ipp_reporter'
require_relative 'ipp_updater'
require_relative 'ipp_migration_reporter'


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


    desc 'creates a post-migration report of price policy and order details failures'
    task report_migration: :environment do
      pp_ids = [ 937, 938, 939, 940, 1122, 1123, 1124, 1125, 2604, 2605, 2606, 2607, 3986, 3987, 3988, 3989,
                 7911, 7913, 7914, 9931, 9932, 9933, 9934, 13191, 13192, 13193, 13194, 14351, 14354, 14355 ]

      od_ids = [ 132401, 132535, 132890, 133289, 133304, 133382, 134012, 134228, 134317, 134450, 134730,
                 134790, 134912, 135065, 135354, 136132, 136334, 136335, 136416, 136788, 136946, 137207,
                 137954, 138203, 138482, 138563, 138742, 140094, 140384, 140390, 140719, 140936, 141034,
                 141343, 141518, 141537, 141804, 143019, 143518, 144081, 144317, 144615, 145074, 145163,
                 145396, 145610, 145693, 146079 ]

      reporter = IppMigrationReporter.new
      reporter.report_price_policies pp_ids
      reporter.report_order_details od_ids
    end

  end
end
