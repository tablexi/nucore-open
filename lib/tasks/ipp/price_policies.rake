require_relative "ipp_reporter"
require_relative "ipp_updater"
require_relative "ipp_migration_reporter"

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
      Performs a dry run of the conversion of old instrument price policies to new and updates pricing on
      new, in process, and completed order details
    DOC
    task update_dry_run: :environment do
      PricePolicy.transaction do
        IppUpdater.new.update_price_policies
        raise ActiveRecord::Rollback
      end
    end

    desc <<-DOC
      Converts old instrument price policies to new and updates pricing on
      new, in process, and completed order details
    DOC
    task update: :environment do
      IppUpdater.new.update_price_policies
      # For UIC, we don't want to do this.
      # IppUpdater.new.update_order_details
    end

    desc "updates order details from attributes in a json file"
    task :update_journaled_details, [:json_file] => :environment do |_t, args|
      oids_to_attrs = IppJsonBuilder.new.parse_json_file args.json_file
      IppUpdater.new.update_journaled_details oids_to_attrs
    end

    desc "creates a json file of order details that are journaled but still complete"
    task serialize_journaled_details: :environment do
      ods = OrderDetail.joins(:product).where("products.type = ?", Instrument.name).where("journal_id IS NOT NULL").where state: "complete"
      IppJsonBuilder.new.build_json_file ods
    end

    desc "creates a json file of order details that are journaled but still complete"
    task serialize_statemented_details: :environment do
      ods = OrderDetail.joins(:product).where("products.type = ?", Instrument.name).where("statement_id IS NOT NULL").where state: "complete"
      IppJsonBuilder.new.build_json_file ods
    end

    desc "creates a report of order details that are journaled but still complete using attributes from a json file"
    task :report_journaled_details, [:json_file] => :environment do |_t, args|
      oids_to_attrs = IppJsonBuilder.new.parse_json_file args.json_file
      IppMigrationReporter.new.report_journaled_details oids_to_attrs
    end

    desc "creates a report of order details that are statemented but still complete using attributes from a json file"
    task :report_statemented_details, [:json_file] => :environment do |_t, args|
      oids_to_attrs = IppJsonBuilder.new.parse_json_file args.json_file
      IppMigrationReporter.new.report_statemented_details oids_to_attrs
    end

    desc "creates a post-migration report of price policy and order details failures"
    task report_migration: :environment do
      pp_ids = [937, 938, 939, 940, 1122, 1123, 1124, 1125, 2604, 2605, 2606, 2607, 3986, 3987, 3988, 3989,
                7911, 7913, 7914, 9931, 9932, 9933, 9934, 13_191, 13_192, 13_193, 13_194, 14_351, 14_354, 14_355]

      od_ids = [132_401, 132_535, 132_890, 133_289, 133_304, 133_382, 134_012, 134_228, 134_317, 134_450, 134_730,
                134_790, 134_912, 135_065, 135_354, 136_132, 136_334, 136_335, 136_416, 136_788, 136_946, 137_207,
                137_954, 138_203, 138_482, 138_563, 138_742, 140_094, 140_384, 140_390, 140_719, 140_936, 141_034,
                141_343, 141_518, 141_537, 141_804, 143_019, 143_518, 144_081, 144_317, 144_615, 145_074, 145_163,
                145_396, 145_610, 145_693, 146_079]

      reporter = IppMigrationReporter.new
      reporter.report_price_policies pp_ids
      reporter.report_order_details od_ids
    end

  end
end
