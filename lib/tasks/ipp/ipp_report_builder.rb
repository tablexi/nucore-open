#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppReportBuilder

  attr_accessor :doc, :builder


  def initialize
    @builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.body {
          doc.article {
            @doc = doc
          }
        }
      }
    end
  end


  def report(detail, actuals, estimates)
    reservation = detail.reservation

    doc.section.comparison {
      doc.h2 detail.to_s
      doc.p "Reserved for #{(reservation.reserve_end_at - reservation.reserve_start_at) / 60} minutes"
      doc.p "Used for #{(reservation.actual_end_at - reservation.actual_start_at) / 60} minutes"
      doc.table {
        doc.tr {
          doc.th 'Old Policy', colspan: 2
          doc.th 'New Policy'
        }

        doc.tr {
          doc.td 'Estimated Cost'
          doc.td detail.estimated_cost.to_f
          doc.td estimates[:cost].to_f
        }

        doc.tr {
          doc.td 'Estimated Subsidy'
          doc.td detail.estimated_subsidy.to_f
          doc.td estimates[:subsidy].to_f
        }

        doc.tr {
          doc.td 'Actual Cost'
          doc.td detail.actual_cost.to_f
          doc.td actuals[:cost].to_f
        }

        doc.tr {
          doc.td 'Actual Subsidy'
          doc.td detail.actual_subsidy.to_f
          doc.td actuals[:subsidy].to_f
        }
      }
    }
  end


  def summarize(reporter)
    doc.section.summary! {
      doc.h2 'Summary'
      doc.p "#{reporter.details.size} new, in process, or completed reservations processed"
      doc.p "#{reporter.changed} had different prices while #{reporter.details.size - reporter.changed} were the same"
    }
  end


  def report_errors(reporter)
    doc.section.errors! {
      doc.details {
        doc.summary 'Errors'
        reporter.errors.each { |err| doc.p err }
      }
    }
  end


  def render
    "<!DOCTYPE html>#{builder.doc.root.to_s}"
  end

end
