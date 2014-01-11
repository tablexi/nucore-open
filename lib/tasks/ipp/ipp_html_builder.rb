#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppHtmlBuilder

  attr_reader :html


  def initialize
    @html = Nokogiri::HTML::Document.new

    Nokogiri::HTML::Builder.with(html) do |doc|
      doc.html {
        doc.head {
          doc.link rel: 'stylesheet', type: 'text/css', href: File.expand_path('report.css', File.dirname(__FILE__))
        }
        doc.body {
          doc.article {
          }
        }
      }
    end
  end


  def report(detail, actuals, estimates)
    reservation = detail.reservation
    product = detail.product

    append_to_article do |doc|
      doc.section.comparison {
        doc.h2 "#{product.facility.name} | #{product.name} | #{detail.to_s}"
        doc.p "Reserved for #{(reservation.reserve_end_at - reservation.reserve_start_at) / 60} minutes"
        doc.p "Used for #{(reservation.actual_end_at - reservation.actual_start_at) / 60} minutes"
        doc.table(border: 1) {
          doc.tr {
            doc.th
            doc.th 'Old'
            doc.th 'New'
          }

          doc.tr {
            doc.td.label 'Estimated Cost'
            doc.td detail.estimated_cost.to_f
            doc.td estimates[:cost].to_f
          }

          doc.tr {
            doc.td.label 'Estimated Subsidy'
            doc.td detail.estimated_subsidy.to_f
            doc.td estimates[:subsidy].to_f
          }

          doc.tr {
            doc.td.label 'Actual Cost'
            doc.td detail.actual_cost.to_f
            doc.td actuals[:cost].to_f
          }

          doc.tr {
            doc.td.label 'Actual Subsidy'
            doc.td detail.actual_subsidy.to_f
            doc.td actuals[:subsidy].to_f
          }
        }
      }
    end
  end


  def summarize(reporter)
    append_to_article do |doc|
      doc.section.summary! {
        doc.h2 'Summary'
        doc.p "#{reporter.details.size} new, in process, or completed reservations processed"
        doc.p "#{reporter.changed} had different prices while #{reporter.details.size - reporter.changed} were the same"
      }
    end
  end


  def report_errors(reporter)
    append_to_article do |doc|
      doc.section.errors! {
        doc.details {
          doc.summary 'Errors'
          reporter.errors.each { |err| doc.pre err }
        }
      }
    end
  end


  def render
    File.write 'price_change_report.html', "<!DOCTYPE html>#{html.root.to_s}"
  end


  def append_to_article
    Nokogiri::HTML::Builder.with(html.at('article')) {|doc| yield doc }
  end
end
